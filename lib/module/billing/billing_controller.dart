// lib/modules/billing/billing_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/billing_repository.dart';
import '../../services/local_storage_service.dart';
import '../../core/utils/logger.dart';

class BillingController extends GetxController {
  final BillingRepository _billingRepo = Get.find<BillingRepository>();

  final RxList<InvoiceModel> pendingInvoices = <InvoiceModel>[].obs;
  final RxBool   isLoading          = true.obs;
  final RxBool   isGenerating       = false.obs;
  final RxDouble totalPendingAmount = 0.0.obs;
  final Rxn<CustomerModel> selectedCustomer = Rxn<CustomerModel>();

  String? get vendorId => LocalStorageService.getVendor()?.id;
  List<CustomerModel> get customers => LocalStorageService.getCustomers()
      .where((c) => c.isActive).toList();

  StreamSubscription? _sub;

  @override
  void onReady() {
    super.onReady();
    _initStream();
  }

  void _initStream() {
    if (vendorId == null) return;
    _sub = _billingRepo.watchPendingInvoices(vendorId!).listen(
          (list) {
        pendingInvoices.assignAll(list);
        totalPendingAmount.value =
            list.fold(0, (sum, inv) => sum + inv.pendingAmount);
        isLoading.value = false;
      },
      onError: (e) {
        AppLogger.e('Billing stream error', e);
        isLoading.value = false;
      },
    );
  }

  Future<void> generateBillForCustomer(CustomerModel customer) async {
    if (vendorId == null) return;
    isGenerating.value = true;
    final now = DateTime.now();
    final result = await _billingRepo.generateMonthlyInvoice(
      vendorId: vendorId!,
      customer: customer,
      month: now.month,
      year: now.year,
    );
    result.fold(
          (f) => Get.snackbar('Error', f.message,
          snackPosition: SnackPosition.TOP),
          (inv) => Get.snackbar('✅ Bill Generated',
          '₹${inv.totalAmount.toStringAsFixed(0)} for ${customer.name}',
          snackPosition: SnackPosition.TOP),
    );
    isGenerating.value = false;
  }

  Future<void> recordPayment(InvoiceModel invoice, double amount,
      String method) async {
    if (vendorId == null) return;
    final result = await _billingRepo.recordPayment(
      vendorId:      vendorId!,
      invoiceId:     invoice.id,
      customerId:    invoice.customerId,
      amount:        amount,
      paymentMethod: method,
    );
    result.fold(
          (f) => Get.snackbar('Error', f.message, snackPosition: SnackPosition.TOP),
          (_) => Get.snackbar('💰 Payment Recorded',
          '₹${amount.toStringAsFixed(0)} from ${invoice.customerName}',
          snackPosition: SnackPosition.TOP),
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}