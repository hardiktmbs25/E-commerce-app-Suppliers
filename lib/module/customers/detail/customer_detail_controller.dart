// lib/modules/customers/detail/customer_detail_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/delivery_model.dart';
import '../../../data/repositories/billing_repository.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../../services/local_storage_service.dart';
import '../../../core/utils/logger.dart';
import '../../../routes/app_routes.dart';
import 'package:flutter/material.dart';

class CustomerDetailController extends GetxController {
  final BillingRepository  _billingRepo  = Get.find<BillingRepository>();
  final DeliveryRepository _deliveryRepo = Get.find<DeliveryRepository>();

  final Rxn<CustomerModel>    customer  = Rxn<CustomerModel>();
  final RxList<InvoiceModel>  invoices  = <InvoiceModel>[].obs;
  final RxList<DeliveryModel> recentDeliveries = <DeliveryModel>[].obs;
  final RxBool isLoading         = true.obs;
  final RxBool isGeneratingBill  = false.obs;

  StreamSubscription? _invoiceSub;
  String? get vendorId => LocalStorageService.getVendor()?.id;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is CustomerModel) {
      customer.value = Get.arguments as CustomerModel;
      _initStreams();
    }
  }

  void _initStreams() {
    if (vendorId == null || customer.value == null) return;

    _invoiceSub = _billingRepo
        .watchCustomerInvoices(vendorId!, customer.value!.id)
        .listen(
          (list) {
        invoices.assignAll(list);
        isLoading.value = false;
      },
      onError: (e) {
        AppLogger.e('CustomerDetail invoices error', e);
        isLoading.value = false;
      },
    );

    // Load recent deliveries
    _loadRecentDeliveries();
  }

  Future<void> _loadRecentDeliveries() async {
    if (vendorId == null || customer.value == null) return;
    final now = DateTime.now();
    final result = await _deliveryRepo.fetchDeliveryHistory(
      vendorId!,
      startDate:  DateTime(now.year, now.month, 1),
      customerId: customer.value!.id,
    );
    result.fold(
          (f) => AppLogger.e('Recent deliveries error', f.message),
          (list) => recentDeliveries.assignAll(list),
    );
  }

  Future<void> generateBill() async {
    if (vendorId == null || customer.value == null) return;
    isGeneratingBill.value = true;
    final now = DateTime.now();
    final result = await _billingRepo.generateMonthlyInvoice(
      vendorId:  vendorId!,
      customer:  customer.value!,
      month:     now.month,
      year:      now.year,
    );
    result.fold(
          (f) => Get.snackbar('Error', f.message,
          backgroundColor: Colors.red, colorText: Colors.white,
          snackPosition: SnackPosition.TOP),
          (invoice) => Get.snackbar('✅ Bill Generated',
          'Invoice ₹${invoice.totalAmount.toStringAsFixed(0)} created.',
          snackPosition: SnackPosition.TOP),
    );
    isGeneratingBill.value = false;
  }

  void editCustomer() => Get.toNamed(Routes.addCustomer, arguments: customer.value);

  void goToAddDelivery() =>
      Get.toNamed(Routes.addDelivery, arguments: customer.value);

  int get deliveredThisMonth =>
      recentDeliveries.where((d) => d.isDelivered).length;
  int get missedThisMonth =>
      recentDeliveries.where((d) => d.isMissed).length;

  @override
  void onClose() {
    _invoiceSub?.cancel();
    super.onClose();
  }
}