// lib/modules/subscriptions/add/add_subscription_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/subscription_model.dart';
import '../../../services/local_storage_service.dart';

class AddSubscriptionController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final formKey = GlobalKey<FormState>();
  final quantityCtrl     = TextEditingController(text: '1');
  final pricePerUnitCtrl = TextEditingController();
  final slotCtrl         = TextEditingController();

  final selectedCustomer  = Rxn<CustomerModel>();
  final selectedService   = 'milk'.obs;
  final selectedFrequency = SubscriptionFrequency.daily.obs;
  final selectedUnit      = 'litre'.obs;
  final isLoading         = false.obs;

  String? get vendorId => LocalStorageService.getVendor()?.id;
  List<CustomerModel> get customers => LocalStorageService.getCustomers()
      .where((c) => c.isActive).toList();

  final unitOptions      = ['litre', 'packet', 'copy', 'box', 'kg', 'piece'];
  final serviceOptions   = ['milk', 'water', 'newspaper', 'tiffin', 'grocery', 'custom'];
  final frequencyOptions = SubscriptionFrequency.values;

  double get pricePerDelivery {
    final q = double.tryParse(quantityCtrl.text) ?? 1;
    final p = double.tryParse(pricePerUnitCtrl.text) ?? 0;
    return q * p;
  }

  String? validateRequired(String? v, String field) =>
      v == null || v.trim().isEmpty ? '$field is required' : null;

  String? validateNumber(String? v, String field) {
    if (v == null || v.isEmpty) return '$field is required';
    if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Enter a valid number';
    return null;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedCustomer.value == null) {
      Get.snackbar('Error', 'Please select a customer.',
          snackPosition: SnackPosition.TOP);
      return;
    }
    isLoading.value = true;

    final id  = const Uuid().v4();
    final now = DateTime.now();
    final sub = SubscriptionModel(
      id:               id,
      vendorId:         vendorId!,
      customerId:       selectedCustomer.value!.id,
      customerName:     selectedCustomer.value!.name,
      serviceTypeStr:   selectedService.value,
      frequencyStr:     selectedFrequency.value.name,
      quantity:         double.parse(quantityCtrl.text),
      unit:             selectedUnit.value,
      pricePerUnit:     double.parse(pricePerUnitCtrl.text),
      pricePerDelivery: pricePerDelivery,
      deliverySlot:     slotCtrl.text.trim(),
      startDate:        now,
      createdAt:        now,
      updatedAt:        now,
    );

    try {
      final col = '${AppConstants.colVendors}/$vendorId/${AppConstants.colSubscriptions}';
      await _db.collection(col).doc(id).set(sub.toFirestore());
      Get.back();
      Get.snackbar('🎉 Subscription Added',
          '${sub.customerName} subscribed to ${sub.serviceTypeStr}.',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save subscription.',
          snackPosition: SnackPosition.TOP);
    }
    isLoading.value = false;
  }

  @override
  void onClose() {
    quantityCtrl.dispose();
    pricePerUnitCtrl.dispose();
    slotCtrl.dispose();
    super.onClose();
  }
}