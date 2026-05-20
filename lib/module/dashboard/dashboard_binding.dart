// lib/module/dashboard/dashboard_binding.dart
import 'package:get/get.dart';
import '../../data/repositories/billing_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../services/delivery_scheduler_service.dart';
import '../billing/billing_controller.dart';
import '../customers/customers_controller.dart';
import '../deliveries/deliveries_controller.dart';
import '../profile/profile_controller.dart';
import 'dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // AuthService, ConnectivityService, NotificationService, VendorRepository
    // are registered permanently in main.dart

    // ── DeliverySchedulerService ─────────────────────────────────────────
    // Must be registered BEFORE DeliveriesController because the controller
    // calls Get.find<DeliverySchedulerService>() at construction time.
    // DashboardScreen uses IndexedStack so all tab controllers are built at once.
    Get.put<DeliverySchedulerService>(
      DeliverySchedulerService(),
      permanent: true,
    );

    // ── Repositories ─────────────────────────────────────────────────────
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<DeliveryRepository>(() => DeliveryRepository(), fenix: true);
    Get.lazyPut<BillingRepository>(() => BillingRepository(), fenix: true);

    // ── Controllers ───────────────────────────────────────────────────────
    Get.lazyPut<DashboardController>(() => DashboardController());

    // Tab controllers — registered here because DashboardScreen uses IndexedStack,
    // meaning all tab screens are built at once and their controllers must exist
    // before the widgets call Get.find<>().
    Get.lazyPut<CustomersController>(() => CustomersController(), fenix: true);
    Get.lazyPut<DeliveriesController>(() => DeliveriesController(), fenix: true);
    Get.lazyPut<BillingController>(() => BillingController(), fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
  }
}