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

  SelectedPlanItem({
    required this.id,
    required this.plan,
  });
}

class AddSubscriptionController extends GetxController {
  // ─────────────────────────────────────────────────────────────
  // Dependencies
  // ─────────────────────────────────────────────────────────────

  final SubscriptionRepository _repo =
  Get.find<SubscriptionRepository>();

  final GlobalPlanRepository _planRepo =
  Get.put(GlobalPlanRepository());

  // ─────────────────────────────────────────────────────────────
  // Form
  // ─────────────────────────────────────────────────────────────

  final formKey = GlobalKey<FormState>();

  final notesCtrl = TextEditingController();

  // ─────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────

  final selectedCustomer = Rxn<CustomerModel>();

  final startDate = DateTime.now().obs;

  final isLoading = false.obs;

  final selectedPlans = <SelectedPlanItem>[].obs;

  final activePlans = <PlanModel>[].obs;

  final timeSlots = <TimeSlotModel>[].obs;

  final selectedDropdownPlan = Rxn<PlanModel>();

  final Rxn<SubscriptionModel> editingSub = Rxn<SubscriptionModel>();

  // ─────────────────────────────────────────────────────────────
  // Derived
  // ─────────────────────────────────────────────────────────────


  String? get vendorId =>
      LocalStorageService.getVendor()?.id;

  String get vendorService =>
      LocalStorageService.getVendor()?.serviceTypeStr ??
          ServiceConstants.custom;

  List<CustomerModel> get customers =>
      LocalStorageService.getCustomers()
          .where((c) => c.isActive)
          .toList();

  double get totalDeliveryRate {
    return selectedPlans.fold(
      0.0,
          (sum, item) => sum + item.plan.pricePerDelivery,
    );
  }

  double get estimatedMonthlyRevenue {
    return selectedPlans.fold(
      0.0,
          (sum, item) {
        final freq = FrequencyConstants.fromStr(
          item.plan.frequencyStr,
        );

        return sum +
            item.plan.pricePerDelivery *
                FrequencyConstants.monthlyDeliveries(freq);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments is SubscriptionModel) {
      editingSub.value = Get.arguments;
      _prefillEditMode();
    }

    loadPlansAndSlots();
  }

  void _prefillEditMode() {
    final sub = editingSub.value!;
    notesCtrl.text = sub.notes ?? '';
    startDate.value = sub.startDate;
    selectedCustomer.value = LocalStorageService.getCustomer(sub.customerId);

    // Create a pseudo-plan based on current subscription values for display in basket
    // This allows the user to see what they have and optionally remove/replace it.
    final mockPlan = PlanModel(
      id: 'current',
      vendorId: sub.vendorId,
      name: 'Current Config',
      serviceType: sub.serviceTypeStr,
      frequencyStr: sub.frequencyStr,
      quantity: sub.quantity,
      unit: sub.unit,
      pricePerUnit: sub.pricePerUnit,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    selectedPlans.add(SelectedPlanItem(id: 'current', plan: mockPlan));
  }



  // ─────────────────────────────────────────────────────────────
  // Load Plans & Slots
  // ─────────────────────────────────────────────────────────────

  Future<void> loadPlansAndSlots() async {
    if (vendorId == null) return;

    // Load slots
    final slotsResult =
    await _planRepo.fetchTimeSlots(vendorId!);

    slotsResult.fold(
          (failure) {
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      },
          (list) {
        timeSlots.assignAll(list);
      },
    );

    // Load plans
    final plansResult =
    await _planRepo.fetchPlans(vendorId!);

    plansResult.fold(
          (failure) {
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      },
          (list) {
        final filtered = list
            .where(
              (p) =>
          p.isActive &&
              p.serviceType == vendorService,
        )
            .toList();

        activePlans.assignAll(filtered);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Basket Management
  // ─────────────────────────────────────────────────────────────

  void addPlan(PlanModel plan) {
    if (editingSub.value != null) {
      // In edit mode, replace the single item
      selectedPlans.assignAll([
        SelectedPlanItem(
          id: const Uuid().v4(),
          plan: plan,
        ),
      ]);
    } else {
      selectedPlans.add(
        SelectedPlanItem(
          id: const Uuid().v4(),
          plan: plan,
        ),
      );
    }

    selectedDropdownPlan.value = null;
  }


  void removePlan(String instanceId) {
    selectedPlans.removeWhere(
          (item) => item.id == instanceId,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Date Picker
  // ─────────────────────────────────────────────────────────────

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: startDate.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      startDate.value = picked;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────────────────────

  bool _validateAll() {
    if (vendorId == null) {
      Get.snackbar(
        'Error',
        'Vendor not found.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return false;
    }

    if (selectedCustomer.value == null) {
      Get.snackbar(
        '⚠️ Customer Required',
        'Please select a customer.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return false;
    }

    if (selectedPlans.isEmpty) {
      Get.snackbar(
        '⚠️ Plan Required',
        'Please add at least one plan.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  // ─────────────────────────────────────────────────────────────
  // Save Subscription
  // ─────────────────────────────────────────────────────────────

  Future<void> save() async {
    if (!_validateAll()) return;

    isLoading.value = true;

    final customer = selectedCustomer.value!;

    try {
      if (editingSub.value != null) {
        // ── UPDATE MODE ──────────────────────────────────────────────
        final item = selectedPlans.first;
        final plan = item.plan;

        final resolvedSlots = plan.deliverySlotIds
            .map((slotId) {
          final slot = timeSlots.firstWhereOrNull((s) => s.id == slotId);
          return slot?.startTime ?? '07:00 AM';
        }).toList();

        if (resolvedSlots.isEmpty) resolvedSlots.add('07:00 AM');

        final updatedSub = editingSub.value!.copyWith(
          serviceTypeStr: plan.serviceType,
          frequencyStr: plan.frequencyStr,
          quantity: plan.quantity,
          pricePerUnit: plan.pricePerUnit,
          pricePerDelivery: plan.pricePerDelivery,
          deliverySlots: resolvedSlots,
          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          autoResume: true, // Reset autoResume on edit
        );

        final result = await _repo.updateSubscription(vendorId!, updatedSub);

        result.fold(
                (failure) => Get.snackbar('Error', failure.message, snackPosition: SnackPosition.TOP),
                (_) {
              Get.back(result: updatedSub);
              Get.snackbar('✅ Updated', 'Subscription updated successfully.', snackPosition: SnackPosition.TOP);
            }
        );
      } else {
        // ── CREATE MODE ──────────────────────────────────────────────
        int successCount = 0;
        SubscriptionModel? lastSavedSub;

        for (final item in selectedPlans) {
          final plan = item.plan;

          final resolvedSlots = plan.deliverySlotIds
              .map((slotId) {
            final slot = timeSlots.firstWhereOrNull(
                  (s) => s.id == slotId,
            );

            return slot?.startTime ?? '07:00 AM';
          })
              .toList();

          if (resolvedSlots.isEmpty) {
            resolvedSlots.add('07:00 AM');
          }

          final result = await _repo.createSubscription(
            vendorId: vendorId!,
            customerId: customer.id,
            customerName: customer.name,
            serviceType: plan.serviceType,
            frequency: plan.frequencyStr,
            quantity: plan.quantity,
            unit: plan.unit,
            pricePerUnit: plan.pricePerUnit,
            deliverySlot: resolvedSlots.first,
            deliverySlots: resolvedSlots,
            notes: notesCtrl.text.trim().isEmpty
                ? null
                : notesCtrl.text.trim(),
            startDate: startDate.value,
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

              // Trigger immediate generation for today/tomorrow if applicable
            },
          );
        }

        if (successCount == selectedPlans.length) {
          Get.back(result: lastSavedSub);

          Get.snackbar(
            '✅ Subscription Added',
            '$successCount subscription(s) created successfully.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        '❌ Error',
        'Something went wrong while saving subscription.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }


  // ─────────────────────────────────────────────────────────────
  // Cleanup
  // ─────────────────────────────────────────────────────────────

  @override
  void onClose() {
    notesCtrl.dispose();
    super.onClose();
  }
}