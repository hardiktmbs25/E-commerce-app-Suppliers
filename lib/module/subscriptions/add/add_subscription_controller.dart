// lib/module/subscriptions/add/add_subscription_controller.dart
//
// CHANGES:
//  1. Vendor's serviceType is read from LocalStorageService to auto-restrict
//     service options to only what this vendor provides.
//  2. selectedUnit auto-updates when selectedService changes via a reaction.
//  3. Uses new DeliveryFrequency / FrequencyConstants.
//  4. deliveryTimeSlots: a RxList<String> that grows/shrinks based on
//     frequency (1 slot = once daily, 2 = twice daily, 3 = thrice daily).
//  5. Customer validation shows a clear snackbar, prevents save.
//  6. Form reset on onClose.
//  7. No direct Firestore in controller – delegates to SubscriptionRepository.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_constants.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/subscription_model.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../services/delivery_scheduler_service.dart';
import '../../../services/local_storage_service.dart';

class AddSubscriptionController extends GetxController {
  final SubscriptionRepository _repo = Get.find<SubscriptionRepository>();
  final DeliverySchedulerService _scheduler = Get.find<DeliverySchedulerService>();

  // ── Form keys & controllers ─────────────────────────────────────────────
  final formKey          = GlobalKey<FormState>();
  final quantityCtrl     = TextEditingController(text: '1');
  final pricePerUnitCtrl = TextEditingController();
  final notesCtrl        = TextEditingController();

  // ── Observable state ────────────────────────────────────────────────────
  final selectedCustomer   = Rxn<CustomerModel>();
  final selectedService    = ''.obs;          // set in onInit from vendor
  final selectedFrequency  = DeliveryFrequency.onceDaily.obs;
  final selectedUnit       = ''.obs;          // auto-set when service changes
  final startDate          = DateTime.now().obs;
  final isLoading          = false.obs;

  /// Delivery time slot list – length matches timeSlotsRequired for frequency.
  final deliveryTimeSlots  = <String>[].obs;

  // ── Derived ─────────────────────────────────────────────────────────────
  String? get vendorId => LocalStorageService.getVendor()?.id;

  /// The single service this vendor offers.
  String get vendorService =>
      LocalStorageService.getVendor()?.serviceTypeStr ?? ServiceConstants.custom;

  List<CustomerModel> get customers =>
      LocalStorageService.getCustomers().where((c) => c.isActive).toList();

  List<String> get unitOptions => ServiceConstants.unitsFor(selectedService.value);

  int get requiredSlotCount =>
      FrequencyConstants.timeSlotsRequired(selectedFrequency.value);

  double get pricePerDelivery {
    final q = double.tryParse(quantityCtrl.text) ?? 1;
    final p = double.tryParse(pricePerUnitCtrl.text) ?? 0;
    return q * p;
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    // Lock service to vendor's service type
    final service = vendorService;
    selectedService.value = service;
    selectedUnit.value    = ServiceConstants.defaultUnit(service);

    // Initialise with 1 empty time slot
    _syncSlotCount();

    // When frequency changes → adjust slot count
    ever(selectedFrequency, (_) => _syncSlotCount());

    // When service changes → reset unit to default for that service
    ever(selectedService, (s) {
      final units = ServiceConstants.unitsFor(s);
      if (!units.contains(selectedUnit.value)) {
        selectedUnit.value = ServiceConstants.defaultUnit(s);
      }
    });
  }

  // ── Slot management ──────────────────────────────────────────────────────

  void _syncSlotCount() {
    final needed = requiredSlotCount;
    while (deliveryTimeSlots.length < needed) {
      deliveryTimeSlots.add('');
    }
    while (deliveryTimeSlots.length > needed) {
      deliveryTimeSlots.removeLast();
    }
  }

  Future<void> pickTimeSlot(int index) async {
    final picked = await showTimePicker(
      context: Get.context!,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final formatted = picked.format(Get.context!);
    deliveryTimeSlots[index] = formatted;
    deliveryTimeSlots.refresh();
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

  // ── Validation ───────────────────────────────────────────────────────────

  String? validateNumber(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    final parsed = double.tryParse(v.trim());
    if (parsed == null || parsed <= 0) return 'Enter a valid number';
    return null;
  }

  bool _validateAll() {
    if (selectedCustomer.value == null) {
      Get.snackbar(
        '⚠️ Customer Required',
        'Please choose a customer before saving.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
      );
      return false;
    }

    if (!formKey.currentState!.validate()) return false;

    // Validate all required time slots are filled
    for (int i = 0; i < requiredSlotCount; i++) {
      if (deliveryTimeSlots.length <= i || deliveryTimeSlots[i].isEmpty) {
        Get.snackbar(
          '⚠️ Delivery Time Required',
          requiredSlotCount > 1
              ? 'Please set all ${requiredSlotCount} delivery times.'
              : 'Please set a delivery time.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
        return false;
      }
    }

    return true;
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> save() async {
    if (!_validateAll()) return;

    isLoading.value = true;

    try {
      final id      = const Uuid().v4();
      final now     = DateTime.now();
      final customer = selectedCustomer.value!;
      final slots    = deliveryTimeSlots.toList();

      final sub = SubscriptionModel(
        id:               id,
        vendorId:         vendorId!,
        customerId:       customer.id,
        customerName:     customer.name,
        serviceTypeStr:   selectedService.value,
        frequencyStr:     FrequencyConstants.toStr(selectedFrequency.value),
        quantity:         double.parse(quantityCtrl.text.trim()),
        unit:             selectedUnit.value,
        pricePerUnit:     double.parse(pricePerUnitCtrl.text.trim()),
        pricePerDelivery: pricePerDelivery,
        deliverySlot:     slots.first,      // legacy field
        deliverySlots:    slots,
        startDate:        startDate.value,
        notes:            notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        createdAt:        now,
        updatedAt:        now,
      );

      final result = await _repo.createSubscription(
        vendorId:      vendorId!,
        customerId:    customer.id,
        customerName:  customer.name,
        serviceType:   sub.serviceTypeStr,
        frequency:     sub.frequencyStr,
        quantity:      sub.quantity,
        unit:          sub.unit,
        pricePerUnit:  sub.pricePerUnit,
        deliverySlot:  sub.deliverySlot,
        deliverySlots: sub.deliverySlots,
        notes:         sub.notes,
        startDate:     sub.startDate,
      );

      result.fold(
            (f) {
          Get.snackbar(
            '❌ Error',
            f.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
        },
            (saved) async {
          await _scheduler.generateForNewSubscription(
            vendorId!,
            saved,
            customer.address,
          );

          Get.back(result: saved);

          Get.snackbar(
            '✅ Subscription Added',
            '${customer.name} subscription created successfully',
            snackPosition: SnackPosition.TOP,
          );
        },
      );
    } catch (e) {
      Get.snackbar(
        '❌ Error',
        'An unexpected error occurred.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Cleanup ──────────────────────────────────────────────────────────────

  @override
  void onClose() {
    quantityCtrl.dispose();
    pricePerUnitCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }
}