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
//  8. [NEW] Loads active plan templates & vendor time slots and auto-fills
//     the form fields when a plan is selected.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_constants.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/subscription_model.dart';
import '../../../data/models/plan_model.dart';
import '../../../data/models/time_slot_model.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../data/repositories/global_plan_repository.dart';
import '../../../services/delivery_scheduler_service.dart';
import '../../../services/local_storage_service.dart';

class SelectedPlanItem {
  final String id;
  final PlanModel plan;

  SelectedPlanItem({required this.id, required this.plan});
}

class AddSubscriptionController extends GetxController {
  final SubscriptionRepository _repo = Get.find<SubscriptionRepository>();
  final DeliverySchedulerService _scheduler = Get.find<DeliverySchedulerService>();
  final GlobalPlanRepository _planRepo = Get.put(GlobalPlanRepository());

  // ── Form keys & controllers ─────────────────────────────────────────────
  final formKey          = GlobalKey<FormState>();
  final notesCtrl        = TextEditingController();

  // ── Observable state ────────────────────────────────────────────────────
  final selectedCustomer   = Rxn<CustomerModel>();
  final startDate          = DateTime.now().obs;
  final isLoading          = false.obs;

  /// Selected plans inside the multi-plan subscription builder basket
  final selectedPlans      = <SelectedPlanItem>[].obs;

  /// Active plan templates for dropdown selection
  final activePlans        = <PlanModel>[].obs;

  /// Time slot templates loaded to resolve slot IDs to labels
  final timeSlots          = <TimeSlotModel>[].obs;

  /// Currently selected plan template in the dropdown
  final selectedDropdownPlan = Rxn<PlanModel>();

  // ── Derived ─────────────────────────────────────────────────────────────
  String? get vendorId => LocalStorageService.getVendor()?.id;

  /// The single service this vendor offers.
  String get vendorService =>
      LocalStorageService.getVendor()?.serviceTypeStr ?? ServiceConstants.custom;

  List<CustomerModel> get customers =>
      LocalStorageService.getCustomers().where((c) => c.isActive).toList();

  /// Total delivery rate (price per delivery) aggregated across all selected plans
  double get totalDeliveryRate =>
      selectedPlans.fold(0.0, (sum, item) => sum + item.plan.pricePerDelivery);

  /// Total estimated monthly revenue aggregated across all selected plans
  double get estimatedMonthlyRevenue {
    return selectedPlans.fold(0.0, (sum, item) {
      final freq = FrequencyConstants.fromStr(item.plan.frequencyStr);
      return sum + item.plan.pricePerDelivery * FrequencyConstants.monthlyDeliveries(freq);
    });
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    // Fetch vendor plans and time slots
    loadPlansAndSlots();
  }

  Future<void> loadPlansAndSlots() async {
    if (vendorId == null) return;

    // Fetch time slots first so we can map IDs to labels
    final slotsResult = await _planRepo.fetchTimeSlots(vendorId!);
    slotsResult.fold(
          (f) => null,
          (list) => timeSlots.assignAll(list),
    );

    // Fetch plans and filter active plans of this vendor's service type
    final plansResult = await _planRepo.fetchPlans(vendorId!);
    plansResult.fold(
          (f) => null,
          (list) {
        final filtered = list.where((p) => p.isActive && p.serviceType == vendorService).toList();
        activePlans.assignAll(filtered);
      },
    );
  }

  // ── Plan Basket Management ─────────────────────────────────────────────────

  void addPlan(PlanModel plan) {
    selectedPlans.add(SelectedPlanItem(
      id: const Uuid().v4(),
      plan: plan,
    ));
    selectedDropdownPlan.value = null; // Reset selection in dropdown
  }

  void removePlan(String instanceId) {
    selectedPlans.removeWhere((item) => item.id == instanceId);
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

    if (selectedPlans.isEmpty) {
      Get.snackbar(
        '⚠️ Plan Required',
        'Please add at least one plan template to your subscription.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
      return false;
    }

    return true;
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> save() async {
    if (!_validateAll()) return;

    isLoading.value = true;
    final customer = selectedCustomer.value!;

    try {
      int successCount = 0;
      SubscriptionModel? lastSavedSub;

      for (final item in selectedPlans) {
        final plan = item.plan;

        // Resolve the plan's slot IDs to actual time labels
        final resolvedSlots = plan.deliverySlotIds.map((id) {
          final slot = timeSlots.firstWhereOrNull((s) => s.id == id);
          return slot?.label ?? '07:00 AM';
        }).toList();

        if (resolvedSlots.isEmpty) {
          resolvedSlots.add('07:00 AM');
        }

        final result = await _repo.createSubscription(
          vendorId:      vendorId!,
          customerId:    customer.id,
          customerName:  customer.name,
          serviceType:   plan.serviceType,
          frequency:     plan.frequencyStr,
          quantity:      plan.quantity,
          unit:          plan.unit,
          pricePerUnit:  plan.pricePerUnit,
          deliverySlot:  resolvedSlots.first,
          deliverySlots: resolvedSlots,
          notes:         notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          startDate:     startDate.value,
        );

        await result.fold(
              (failure) async {
            Get.snackbar(
              '❌ Error adding "${plan.name}"',
              failure.message,
              snackPosition: SnackPosition.TOP,
              backgroundColor: AppColors.error,
              colorText: Colors.white,
            );
          },
              (savedSub) async {
            successCount++;
            lastSavedSub = savedSub;
            // Generate scheduled deliveries for the new subscription
            await _scheduler.generateForNewSubscription(
              vendorId!,
              savedSub,
              customer.address,
            );
          },
        );
      }

      if (successCount == selectedPlans.length) {
        Get.back(result: lastSavedSub);
        Get.snackbar(
          '✅ Subscriptions Added',
          'Successfully added $successCount subscription(s) for ${customer.name}.',
          snackPosition: SnackPosition.TOP,
        );
      }
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
    notesCtrl.dispose();
    super.onClose();
  }
}