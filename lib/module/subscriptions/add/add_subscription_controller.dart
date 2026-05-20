// lib/modules/subscriptions/add/add_subscription_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/subscription_model.dart';
import '../../../services/delivery_scheduler_service.dart';
import '../../../services/local_storage_service.dart';

class AddSubscriptionController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DeliverySchedulerService _scheduler = Get.find<DeliverySchedulerService>();

  final formKey          = GlobalKey<FormState>();
  final quantityCtrl     = TextEditingController(text: '1');
  final pricePerUnitCtrl = TextEditingController();
  final slotCtrl         = TextEditingController(text: '07:00 AM');
  final notesCtrl        = TextEditingController();

  final selectedCustomer  = Rxn<CustomerModel>();
  final selectedService   = 'milk'.obs;
  final selectedFrequency = SubscriptionFrequency.daily.obs;
  final selectedUnit      = 'litre'.obs;
  final selectedCustomDays = <int>[].obs; // for custom frequency
  final startDate         = DateTime.now().obs;
  final isLoading         = false.obs;

  String? get vendorId => LocalStorageService.getVendor()?.id;

  List<CustomerModel> get customers =>
      LocalStorageService.getCustomers().where((c) => c.isActive).toList();

  final unitOptions      = ['litre', 'packet', 'copy', 'box', 'kg', 'piece'];
  final serviceOptions   = ['milk', 'water', 'newspaper', 'tiffin', 'grocery', 'custom'];
  final frequencyOptions = SubscriptionFrequency.values;

  final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  double get pricePerDelivery {
    final q = double.tryParse(quantityCtrl.text) ?? 1;
    final p = double.tryParse(pricePerUnitCtrl.text) ?? 0;
    return q * p;
  }

  String? validateRequired(String? v, String field) =>
      v == null || v.trim().isEmpty ? '$field is required' : null;

  String? validateNumber(String? v, String field) {
    if (v == null || v.isEmpty) return '$field is required';
    if (double.tryParse(v) == null || double.parse(v) <= 0) {
      return 'Enter a valid number';
    }
    return null;
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: startDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) startDate.value = picked;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedCustomer.value == null) {
      Get.snackbar('Error', 'Please select a customer.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
      return;
    }
    if (selectedFrequency.value == SubscriptionFrequency.custom &&
        selectedCustomDays.isEmpty) {
      Get.snackbar('Error', 'Please select at least one delivery day.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
      return;
    }

    isLoading.value = true;

    final id  = const Uuid().v4();
    final now = DateTime.now();
    final customer = selectedCustomer.value!;

    final sub = SubscriptionModel(
      id:               id,
      vendorId:         vendorId!,
      customerId:       customer.id,
      customerName:     customer.name,
      serviceTypeStr:   selectedService.value,
      frequencyStr:     selectedFrequency.value.name,
      quantity:         double.parse(quantityCtrl.text),
      unit:             selectedUnit.value,
      pricePerUnit:     double.parse(pricePerUnitCtrl.text),
      pricePerDelivery: pricePerDelivery,
      deliverySlot:     slotCtrl.text.trim().isEmpty ? '07:00 AM' : slotCtrl.text.trim(),
      startDate:        startDate.value,
      customDays:       selectedCustomDays.toList(),
      notes:            notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      createdAt:        now,
      updatedAt:        now,
    );

    try {
      // 1. Save subscription to Firestore
      final col = '${AppConstants.colVendors}/$vendorId/${AppConstants.colSubscriptions}';
      await _db.collection(col).doc(id).set(sub.toFirestore());

      // 2. Save to local cache so scheduler can access it immediately
      await LocalStorageService.saveSubscription(sub);

      // 3. Immediately generate today's delivery for this subscription
      //    (if it should deliver today based on frequency)
      await _scheduler.generateForNewSubscription(
          vendorId!, sub, customer.address);

      Get.back(result: sub);
      Get.snackbar(
        '🎉 Subscription Added',
        '${customer.name} subscribed to ${sub.serviceTypeStr}.'
            '${sub.shouldDeliverOn(now) ? " Today\'s delivery added!" : ""}',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to save subscription. Please try again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
    }

    isLoading.value = false;
  }

  @override
  void onClose() {
    quantityCtrl.dispose();
    pricePerUnitCtrl.dispose();
    slotCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }
}