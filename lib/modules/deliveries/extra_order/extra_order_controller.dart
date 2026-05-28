// lib/modules/deliveries/extra_order/extra_order_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../../services/local_storage_service.dart';

class ExtraOrderController extends GetxController {
  final DeliveryRepository _deliveryRepo = Get.find<DeliveryRepository>();
  final CustomerRepository _customerRepo = Get.find<CustomerRepository>();

  final customerSearchCtrl = TextEditingController();
  final quantityCtrl       = TextEditingController(text: '1');
  final amountCtrl         = TextEditingController();
  final notesCtrl          = TextEditingController();

  final RxList<CustomerModel> customerSuggestions = <CustomerModel>[].obs;
  final Rx<CustomerModel?> selectedCustomer       = Rx<CustomerModel?>(null);
  final RxString serviceType   = 'milk'.obs;
  final RxString unit          = 'litre'.obs;
  final RxBool   isSubmitting  = false.obs;

  String? get vendorId => LocalStorageService.getVendor()?.id;

  void searchCustomers(String query) {
    if (query.trim().length < 2) {
      customerSuggestions.clear();
      return;
    }
    final lower = query.toLowerCase();
    final all   = LocalStorageService.getCustomers();
    customerSuggestions.assignAll(
      all.where((c) =>
      c.name.toLowerCase().contains(lower) ||
          c.address.toLowerCase().contains(lower)).take(5).toList(),
    );
  }

  void selectCustomer(CustomerModel customer) {
    selectedCustomer.value = customer;
    customerSearchCtrl.text = customer.name;
    customerSuggestions.clear();
    // Auto-fill service type if known
    serviceType.value = customer.serviceTypeStr;
  }

  void clearCustomer() {
    selectedCustomer.value = null;
    customerSearchCtrl.clear();
    customerSuggestions.clear();
  }

  Future<void> placeOrder() async {
    if (vendorId == null) return;

    if (selectedCustomer.value == null) {
      Get.snackbar('Missing Info', 'Please select a customer.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }

    final qty    = double.tryParse(quantityCtrl.text.trim()) ?? 0;
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;

    if (qty <= 0) {
      Get.snackbar('Invalid Quantity', 'Please enter a valid quantity.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }
    if (amount <= 0) {
      Get.snackbar('Invalid Amount', 'Please enter a valid amount.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }

    isSubmitting.value = true;

    final result = await _deliveryRepo.placeExtraOrder(
      vendorId:        vendorId!,
      customerId:      selectedCustomer.value!.id,
      customerName:    selectedCustomer.value!.name,
      customerAddress: selectedCustomer.value!.address,
      serviceType:     serviceType.value,
      quantity:        qty,
      unit:            unit.value,
      amount:          amount,
      notes:           notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );

    isSubmitting.value = false;

    result.fold(
          (f) => Get.snackbar('Error', f.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error, colorText: Colors.white),
          (delivery) {
        Get.back(result: delivery);
        Get.snackbar('⚡ Order Placed',
            'Extra order for ${selectedCustomer.value!.name} added to today.',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 3));
      },
    );
  }

  @override
  void onClose() {
    customerSearchCtrl.dispose();
    quantityCtrl.dispose();
    amountCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }
}
