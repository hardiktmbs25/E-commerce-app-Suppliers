// lib/modules/dashboard/dashboard_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/vendor_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/delivery_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/vendor_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/billing_repository.dart';
import '../../services/auth_service.dart';
import '../../services/local_storage_service.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/logger.dart';

/// DashboardController is the single source of truth for all
/// dashboard-level data. It owns 4 Firestore streams simultaneously:
///   vendor → customer stats → today's deliveries → pending invoices
///
/// DATA LOADING STRATEGY:
/// 1. Cold start: returns local Hive cache instantly (zero latency)
/// 2. Firestore streams arrive → overwrite cache → UI rebuilds via Obx
/// 3. Aggregated computed getters derive analytics counts from live lists
///
/// PERFORMANCE:
/// Uses IndexedStack in DashboardScreen so tab controllers are never
/// destroyed on tab switch. Only one set of streams runs per session.
class DashboardController extends GetxController {
  final AuthService         _auth         = Get.find<AuthService>();
  final VendorRepository    _vendorRepo   = Get.find<VendorRepository>();
  final CustomerRepository  _customerRepo = Get.find<CustomerRepository>();
  final DeliveryRepository  _deliveryRepo = Get.find<DeliveryRepository>();
  final BillingRepository   _billingRepo  = Get.find<BillingRepository>();

  // ── State ──────────────────────────────────────────────────────────────
  final Rxn<VendorModel>     vendor            = Rxn<VendorModel>();
  final RxList<CustomerModel>  customers       = <CustomerModel>[].obs;
  final RxList<DeliveryModel>  todayDeliveries = <DeliveryModel>[].obs;
  final RxList<InvoiceModel>   pendingInvoices = <InvoiceModel>[].obs;
  final RxBool isLoading                       = true.obs;
  final RxInt  currentTabIndex                 = 0.obs;

  // Revenue this month (from billing stream)
  final RxDouble monthlyRevenue  = 0.0.obs;
  final RxDouble pendingRevenue  = 0.0.obs;

  StreamSubscription? _vendorSub;
  StreamSubscription? _customersSub;
  StreamSubscription? _deliveriesSub;
  StreamSubscription? _invoicesSub;
  StreamSubscription? _revenueSub;

  // ── Computed getters ───────────────────────────────────────────────────
  int get totalCustomers     => customers.length;
  int get activeCustomers    => customers.where((c) => c.isActive).length;
  int get deliveredToday     => todayDeliveries.where((d) => d.isDelivered).length;
  int get pendingToday       => todayDeliveries.where((d) => d.isPending).length;
  int get missedToday        => todayDeliveries.where((d) => d.isMissed).length;
  int get totalPendingBills  => pendingInvoices.length;
  double get completionRate  =>
      todayDeliveries.isEmpty ? 0 : deliveredToday / todayDeliveries.length;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get todayFormatted =>
      DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());

  @override
  void onReady() {
    super.onReady();
    // Load local cache first for instant display
    _loadFromCache();
    // Then start live streams
    _initStreams();
  }

  void _loadFromCache() {
    vendor.value = LocalStorageService.getVendor();
    customers.assignAll(LocalStorageService.getCustomers());
    todayDeliveries.assignAll(LocalStorageService.getTodayDeliveries());
    isLoading.value = vendor.value == null;
  }

  void _initStreams() {
    final uid = _auth.uid;
    if (uid == null) { Get.offAllNamed(Routes.login); return; }

    // 1. Vendor stream
    _vendorSub = _vendorRepo.watchVendor(uid).listen((v) {
      if (v != null) {
        vendor.value = v;
        isLoading.value = false;
      }
    }, onError: (e) => AppLogger.e('Vendor stream error', e));

    // 2. Customers stream
    _customersSub = _customerRepo.watchCustomers(uid).listen(
          (list) => customers.assignAll(list),
      onError: (e) => AppLogger.e('Customers stream error', e),
    );

    // 3. Today's deliveries stream
    _deliveriesSub = _deliveryRepo.watchTodayDeliveries(uid).listen(
          (list) => todayDeliveries.assignAll(list),
      onError: (e) => AppLogger.e('Deliveries stream error', e),
    );

    // 4. Pending invoices stream
    _invoicesSub = _billingRepo.watchPendingInvoices(uid).listen(
          (list) => pendingInvoices.assignAll(list),
      onError: (e) => AppLogger.e('Invoices stream error', e),
    );

    // 5. Monthly revenue stream
    final now = DateTime.now();
    _revenueSub = _billingRepo.watchMonthlyRevenue(uid, now.month, now.year).listen(
          (data) {
        monthlyRevenue.value  = data['total'] ?? 0;
        pendingRevenue.value  = data['pending'] ?? 0;
      },
      onError: (e) => AppLogger.e('Revenue stream error', e),
    );
  }

  void changeTab(int index) => currentTabIndex.value = index;

  @override
  Future<void> refresh() async {
    _cancelStreams();
    _initStreams();
  }

  Future<void> logout() async {
    _cancelStreams();
    await _auth.logout();
    await LocalStorageService.clearAll();
    Get.offAllNamed(Routes.login);
  }

  void _cancelStreams() {
    _vendorSub?.cancel();
    _customersSub?.cancel();
    _deliveriesSub?.cancel();
    _invoicesSub?.cancel();
    _revenueSub?.cancel();
  }

  @override
  void onClose() {
    _cancelStreams();
    super.onClose();
  }
}