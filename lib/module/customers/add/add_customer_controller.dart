// lib/modules/customers/add/add_customer_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../services/local_storage_service.dart';
import '../../../core/utils/extensions.dart';

class AddCustomerController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();

  final formKey = GlobalKey<FormState>();

  // Form controllers
  final nameCtrl          = TextEditingController();
  final phoneCtrl         = TextEditingController();
  final altPhoneCtrl      = TextEditingController();
  final addressCtrl       = TextEditingController();
  final landmarkCtrl      = TextEditingController();
  final notesCtrl         = TextEditingController();

  // Reactive state
  final selectedService   = 'milk'.obs;
  final selectedRoute     = Rxn<String>();
  final isLoading         = false.obs;
  final isEditMode        = false.obs;

  // If editing an existing customer
  CustomerModel? existingCustomer;

  final serviceOptions = [
    {'value': 'milk',      'label': '🥛 Milk'},
    {'value': 'water',     'label': '💧 Water'},
    {'value': 'newspaper', 'label': '📰 Newspaper'},
    {'value': 'tiffin',    'label': '🍱 Tiffin'},
    {'value': 'grocery',   'label': '🛒 Grocery'},
    {'value': 'custom',    'label': '📦 Other'},
  ];

  @override
  void onInit() {
    super.onInit();
    // Pre-fill if editing
    if (Get.arguments != null && Get.arguments is CustomerModel) {
      existingCustomer = Get.arguments as CustomerModel;
      isEditMode.value = true;
      _prefillForm(existingCustomer!);
    }
  }

  void _prefillForm(CustomerModel c) {
    nameCtrl.text        = c.name;
    phoneCtrl.text       = c.phone;
    altPhoneCtrl.text    = c.alternatePhone ?? '';
    addressCtrl.text     = c.address;
    landmarkCtrl.text    = c.landmark ?? '';
    notesCtrl.text       = c.notes ?? '';
    selectedService.value = c.serviceTypeStr;
  }

  String? validateRequired(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  String? validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'Phone is required';
    if (!v.isValidPhone) return 'Enter valid 10-digit number';
    return null;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;

    final vendorId = LocalStorageService.getVendor()?.id ?? '';

    if (isEditMode.value && existingCustomer != null) {
      final updated = existingCustomer!.copyWith(
        name:           nameCtrl.text.trim(),
        phone:          phoneCtrl.text.trim(),
        alternatePhone: altPhoneCtrl.text.trim().isEmpty ? null : altPhoneCtrl.text.trim(),
        address:        addressCtrl.text.trim(),
        landmark:       landmarkCtrl.text.trim().isEmpty ? null : landmarkCtrl.text.trim(),
        notes:          notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      final result = await _repo.updateCustomer(vendorId, updated);
      result.fold(
            (f) => Get.snackbar('Error', f.message, backgroundColor: Colors.red,
            colorText: Colors.white, snackPosition: SnackPosition.TOP),
            (_) {
          Get.back();
          Get.snackbar('✅ Updated', '${updated.name} updated successfully.',
              snackPosition: SnackPosition.TOP);
        },
      );
    } else {
      final result = await _repo.createCustomer(
        vendorId:      vendorId,
        name:          nameCtrl.text.trim(),
        phone:         phoneCtrl.text.trim(),
        address:       addressCtrl.text.trim(),
        serviceType:   selectedService.value,
        alternatePhone: altPhoneCtrl.text.trim().isEmpty ? null : altPhoneCtrl.text.trim(),
        landmark:      landmarkCtrl.text.trim().isEmpty ? null : landmarkCtrl.text.trim(),
        notes:         notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      result.fold(
            (f) => Get.snackbar('Error', f.message, backgroundColor: Colors.red,
            colorText: Colors.white, snackPosition: SnackPosition.TOP),
            (c) {
          Get.back();
          Get.snackbar('🎉 Added', '${c.name} added successfully.',
              snackPosition: SnackPosition.TOP);
        },
      );
    }

    isLoading.value = false;
  }

  @override
  void onClose() {
    nameCtrl.dispose(); phoneCtrl.dispose(); altPhoneCtrl.dispose();
    addressCtrl.dispose(); landmarkCtrl.dispose(); notesCtrl.dispose();
    super.onClose();
  }
}