// lib/modules/subscriptions/global_plans/global_plans_controller.dart
//
// Changes vs original
// ───────────────────
// • Unit options are now dynamically derived from the chosen service type
//   via kUnitsForService — no more hardcoded flat list.
// • Frequency options use kFrequencies (includes twice_daily / thrice_daily).
// • [selectedSlotIds] tracks the per-plan delivery slot selections;
//   its required length is enforced by [requiredSlotsForFrequency].
// • [onServiceChanged] resets unit to the correct default automatically.
// • [onFrequencyChanged] resets slot selections to match required count.
// • savePlan passes [deliverySlotIds] to the repository.
// • Stream errors are now caught per-stream so one failure doesn't block
//   the other tabs.
// • isSaving is per-form (planSaving / areaSaving / slotSaving) so tabs
//   don't share loading state.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/plan_constants.dart';
import '../../../data/models/delivery_area_model.dart';
import '../../../data/models/plan_model.dart';
import '../../../data/models/time_slot_model.dart';
import '../../../data/repositories/global_plan_repository.dart';
import '../../../services/local_storage_service.dart';

class GlobalPlansController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void onInit() {
    super.onInit();

    tabController = TabController(length: 3, vsync: this);

    if (Get.arguments is int) {
      tabController.index = Get.arguments;
      tabIndex.value = Get.arguments;
    }

    tabController.addListener(() {
      tabIndex.value = tabController.index;
    });

    /// quantity listener
    planQtyCtrl.addListener(() {
      quantity.value =
          double.tryParse(planQtyCtrl.text.trim()) ?? 0;
    });

    /// price listener
    planPriceCtrl.addListener(() {
      price.value =
          double.tryParse(planPriceCtrl.text.trim()) ?? 0;
    });
  }
  final GlobalPlanRepository _repo = Get.find<GlobalPlanRepository>();

  // ── Tab ───────────────────────────────────────────────────────────────────
  final RxInt tabIndex = 0.obs;

  // ── Data ──────────────────────────────────────────────────────────────────
  final RxList<PlanModel>         plans     = <PlanModel>[].obs;
  final RxList<DeliveryAreaModel> areas     = <DeliveryAreaModel>[].obs;
  final RxList<TimeSlotModel>     timeSlots = <TimeSlotModel>[].obs;

  // ── Loading flags ─────────────────────────────────────────────────────────
  final RxBool isLoadingPlans = true.obs;
  final RxBool isLoadingAreas = true.obs;
  final RxBool isLoadingSlots = true.obs;

  // ── Saving flags (separate per form) ──────────────────────────────────────
  final RxBool planSaving = false.obs;
  final RxBool areaSaving = false.obs;
  final RxBool slotSaving = false.obs;

  final Rxn<PlanModel> editingPlan = Rxn<PlanModel>();

  // ── Vendor ────────────────────────────────────────────────────────────────

  String? get vendorId => LocalStorageService.getVendor()?.id;

  StreamSubscription? _plansSub;
  StreamSubscription? _areasSub;
  StreamSubscription? _slotsSub;

  // ══════════════════════════════════════════════════════════════════════════
  // PLAN FORM STATE
  // ══════════════════════════════════════════════════════════════════════════

// ── PLAN FORM STATE ─────────────────────────────────────────────

  final planFormKey   = GlobalKey<FormState>();

  final planNameCtrl  = TextEditingController();
  final planDescCtrl  = TextEditingController();

  final planQtyCtrl   = TextEditingController(text: '1');
  final planPriceCtrl = TextEditingController();

  /// FIXED: reactive values for preview
  final RxDouble quantity = 1.0.obs;
  final RxDouble price = 0.0.obs;

  /// The single service this vendor offers.
  String get vendorService =>
      LocalStorageService.getVendor()?.serviceTypeStr ?? 'custom';

  /// Drives the service-type dropdown.
  late final RxString selectedService = vendorService.obs;

  /// Drives the frequency dropdown.
  final RxString selectedFrequency = kFrequencies.first.obs;

  /// Drives the unit dropdown
  late final RxString selectedUnit =
      defaultUnitForService(vendorService).obs;

  /// Selected slot IDs
  final RxList<String> selectedSlotIds = <String>[].obs;

  /// Selected area IDs
  final RxList<String> selectedAreaIds = <String>[].obs;

  // ── Derived option lists ───────────────────────────────────────────────────

  List<String> get serviceOptions   => kServiceTypes;
  List<String> get frequencyOptions => kFrequencies;

  /// Unit options change based on the selected service type.
  List<String> get unitOptions => unitsForService(selectedService.value);

  /// How many time slots the current frequency requires.
  int get requiredSlotCount =>
      requiredSlotsForFrequency(selectedFrequency.value);

  /// Live preview of the per-delivery price.
  double get planPreviewPrice {
    return quantity.value * price.value;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AREA FORM STATE
  // ══════════════════════════════════════════════════════════════════════════

  final areaFormKey  = GlobalKey<FormState>();
  final areaNameCtrl = TextEditingController();
  final areaPinCtrl  = TextEditingController();
  final areaCityCtrl = TextEditingController();

  // ══════════════════════════════════════════════════════════════════════════
  // TIME-SLOT FORM STATE
  // ══════════════════════════════════════════════════════════════════════════

  final slotFormKey   = GlobalKey<FormState>();
  final slotLabelCtrl = TextEditingController();
  final slotStartCtrl = TextEditingController();
  final slotEndCtrl   = TextEditingController();
  final RxString pickedSlotLabel = ''.obs;

  // ══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void onReady() {
    super.onReady();
    _initStreams();
  }

  void _initStreams() {
    if (vendorId == null) {
      isLoadingPlans.value = false;
      isLoadingAreas.value = false;
      isLoadingSlots.value = false;
      return;
    }

    _plansSub = _repo.watchPlans(vendorId!).listen(
          (p) {
        plans.assignAll(p);
        isLoadingPlans.value = false;
      },
      onError: (e) {
        isLoadingPlans.value = false;
        Get.snackbar('Error', 'Could not load plans.',
            snackPosition: SnackPosition.BOTTOM);
      },
    );

    _areasSub = _repo.watchAreas(vendorId!).listen(
          (a) {
        areas.assignAll(a);
        isLoadingAreas.value = false;
      },
      onError: (e) => isLoadingAreas.value = false,
    );

    _slotsSub = _repo.watchTimeSlots(vendorId!).listen(
          (s) {
        timeSlots.assignAll(s);
        isLoadingSlots.value = false;
      },
      onError: (e) => isLoadingSlots.value = false,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PLAN FORM HANDLERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Called when the service-type dropdown changes.
  /// Resets unit to the correct default for that service.
  void onServiceChanged(String? value) {
    if (value == null || !kServiceTypes.contains(value)) return;
    selectedService.value = value;
    final defaultUnit = defaultUnitForService(value);
    // Keep current unit if it still belongs to the new service type.
    if (!unitsForService(value).contains(selectedUnit.value)) {
      selectedUnit.value = defaultUnit;
    }
  }

  /// Called when the frequency dropdown changes.
  /// Clears slot selections if the required count changes.
  void onFrequencyChanged(String? value) {
    if (value == null) return;
    selectedFrequency.value = value;
    selectedSlotIds.clear();
  }

  /// Toggles a slot ID in [selectedSlotIds] during plan creation.
  /// Enforces the max count for the chosen frequency.
  void toggleSlotId(String slotId) {
    if (selectedSlotIds.contains(slotId)) {
      selectedSlotIds.remove(slotId);
    } else {
      if (selectedSlotIds.length >= requiredSlotCount) {
        Get.snackbar(
          'Slot limit',
          'This frequency needs exactly $requiredSlotCount slot(s).',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      selectedSlotIds.add(slotId);
    }
  }

  /// Toggles an area ID in [selectedAreaIds] during plan creation.
  void toggleAreaId(String areaId) {
    if (selectedAreaIds.contains(areaId)) {
      selectedAreaIds.remove(areaId);
    } else {
      selectedAreaIds.add(areaId);
    }
  }

  void prefillPlan(PlanModel plan) {
    editingPlan.value = plan;
    planNameCtrl.text = plan.name;
    planDescCtrl.text = plan.description;
    planQtyCtrl.text = plan.quantity.toString();
    planPriceCtrl.text = plan.pricePerUnit.toString();
    selectedService.value = plan.serviceType;
    selectedFrequency.value = plan.frequencyStr;
    selectedUnit.value = plan.unit;
    selectedSlotIds.assignAll(plan.deliverySlotIds);
    selectedAreaIds.assignAll(plan.deliveryAreaIds);
  }

  Future<void> savePlan() async {
    if (!(planFormKey.currentState?.validate() ?? false)) return;
    if (vendorId == null) return;

    // Validate slot selection
    if (selectedSlotIds.length != requiredSlotCount) {
      Get.snackbar(
        'Select Time Slots',
        'Please select $requiredSlotCount delivery time slot(s) for this plan.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    planSaving.value = true;

    if (editingPlan.value != null) {
      // UPDATE existing plan
      final updated = editingPlan.value!.copyWith(
        name: planNameCtrl.text.trim(),
        serviceType: selectedService.value,
        frequencyStr: selectedFrequency.value,
        quantity: double.tryParse(planQtyCtrl.text) ?? 1,
        unit: selectedUnit.value,
        pricePerUnit: double.tryParse(planPriceCtrl.text) ?? 0,
        deliverySlotIds: List<String>.from(selectedSlotIds),
        deliveryAreaIds: List<String>.from(selectedAreaIds),
        description: planDescCtrl.text.trim(),
      );

      final result = await _repo.updatePlan(vendorId!, updated);
      planSaving.value = false;

      result.fold(
        (failure) => Get.snackbar('Error', failure.message, snackPosition: SnackPosition.BOTTOM),
        (_) {
          _clearPlanForm();
          Get.back();
          Get.snackbar('✅ Plan Updated', 'Plan updated successfully.', snackPosition: SnackPosition.TOP);
        },
      );
    } else {
      // CREATE new plan
      final result = await _repo.createPlan(
        vendorId:        vendorId!,
        name:            planNameCtrl.text.trim(),
        serviceType:     selectedService.value,
        frequency:       selectedFrequency.value,
        quantity:        double.tryParse(planQtyCtrl.text) ?? 1,
        unit:            selectedUnit.value,
        pricePerUnit:    double.tryParse(planPriceCtrl.text) ?? 0,
        deliverySlotIds: List<String>.from(selectedSlotIds),
        deliveryAreaIds: List<String>.from(selectedAreaIds),
        description:     planDescCtrl.text.trim(),
      );

      planSaving.value = false;

      result.fold(
            (failure) => Get.snackbar(
          'Error', failure.message,
          snackPosition: SnackPosition.BOTTOM,
        ),
            (_) {
          final savedName = planNameCtrl.text.trim();
          _clearPlanForm();
          Get.back();
          Get.snackbar(
            '✅ Plan Created', '"$savedName" added successfully.',
            snackPosition: SnackPosition.TOP,
          );
        },
      );
    }
  }


  Future<void> togglePlanActive(PlanModel plan) async {
    if (vendorId == null) return;
    await _repo.updatePlan(vendorId!, plan.copyWith(isActive: !plan.isActive));
  }

  Future<void> deletePlan(String planId, String planName) async {
    if (vendorId == null) return;
    final result = await _repo.deletePlan(vendorId!, planId);
    result.fold(
          (_) => Get.snackbar('Error', 'Could not delete plan.',
          snackPosition: SnackPosition.BOTTOM),
          (_) => Get.snackbar('Deleted', '"$planName" removed.',
          snackPosition: SnackPosition.TOP),
    );
  }

  void _clearPlanForm() {
    editingPlan.value = null;
    planNameCtrl.clear();
    planDescCtrl.clear();

    planQtyCtrl.text = '1';
    planPriceCtrl.clear();
    selectedService.value   = vendorService;
    selectedFrequency.value = kFrequencies.first;
    selectedUnit.value      = defaultUnitForService(vendorService);
    selectedSlotIds.clear();
    selectedAreaIds.clear();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AREA CRUD
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveArea() async {
    if (!(areaFormKey.currentState?.validate() ?? false)) return;
    if (vendorId == null) return;
    areaSaving.value = true;

    final result = await _repo.createArea(
      vendorId: vendorId!,
      name:     areaNameCtrl.text.trim(),
      pincode:  areaPinCtrl.text.trim().isEmpty ? null : areaPinCtrl.text.trim(),
      city:     areaCityCtrl.text.trim().isEmpty ? null : areaCityCtrl.text.trim(),
    );

    areaSaving.value = false;
    result.fold(
          (_) => Get.snackbar('Error', 'Failed to add area.',
          snackPosition: SnackPosition.BOTTOM),
          (_) {
        final name = areaNameCtrl.text.trim();
        _clearAreaForm();
        Get.back();
        Get.snackbar('✅ Area Added', '$name is now a delivery area.',
            snackPosition: SnackPosition.TOP);
      },
    );
  }

  Future<void> deleteArea(String areaId, String areaName) async {
    if (vendorId == null) return;
    await _repo.deleteArea(vendorId!, areaId);
    Get.snackbar('Removed', '"$areaName" removed.', snackPosition: SnackPosition.TOP);
  }

  void _clearAreaForm() {
    areaNameCtrl.clear();
    areaPinCtrl.clear();
    areaCityCtrl.clear();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TIME-SLOT CRUD
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> pickTime(BuildContext context) async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
      helpText: 'Pick start time',
    );
    if (start == null) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute),
      helpText: 'Pick end time',
    );
    if (end == null) return;

    // ignore: use_build_context_synchronously
    final startFmt = start.format(context);
    // ignore: use_build_context_synchronously
    final endFmt   = end.format(context);
    final label    = '$startFmt – $endFmt';

    slotStartCtrl.text   = startFmt;
    slotEndCtrl.text     = endFmt;
    slotLabelCtrl.text   = label;
    pickedSlotLabel.value = label;
  }

  Future<void> saveTimeSlot() async {
    if (!(slotFormKey.currentState?.validate() ?? false)) return;
    if (vendorId == null) return;
    slotSaving.value = true;

    final result = await _repo.createTimeSlot(
      vendorId:  vendorId!,
      label:     slotLabelCtrl.text.trim(),
      startTime: slotStartCtrl.text.trim(),
      endTime:   slotEndCtrl.text.trim(),
      sortOrder: timeSlots.length,
    );

    slotSaving.value = false;
    result.fold(
          (f) => Get.snackbar('Error', f.message, snackPosition: SnackPosition.BOTTOM),
          (_) {
        final label = slotLabelCtrl.text.trim();
        _clearSlotForm();
        Get.back();
        Get.snackbar('✅ Slot Added', '$label time slot created.',
            snackPosition: SnackPosition.TOP);
      },
    );
  }

  Future<void> deleteTimeSlot(String slotId, String label) async {
    if (vendorId == null) return;
    await _repo.deleteTimeSlot(vendorId!, slotId);
    Get.snackbar('Removed', '"$label" removed.', snackPosition: SnackPosition.TOP);
  }

  void _clearSlotForm() {
    slotLabelCtrl.clear();
    slotStartCtrl.clear();
    slotEndCtrl.clear();
    pickedSlotLabel.value = '';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DISPOSE
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void onClose() {
    _plansSub?.cancel();
    _areasSub?.cancel();
    _slotsSub?.cancel();
    planNameCtrl.dispose();
    planDescCtrl.dispose();
    planQtyCtrl.dispose();
    planPriceCtrl.dispose();
    areaNameCtrl.dispose();
    areaPinCtrl.dispose();
    areaCityCtrl.dispose();
    slotLabelCtrl.dispose();
    slotStartCtrl.dispose();
    slotEndCtrl.dispose();
    super.onClose();
  }
}
