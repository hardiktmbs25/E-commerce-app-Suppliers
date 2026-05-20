// lib/module/subscriptions/global_plans/global_plans_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/delivery_area_model.dart';
import '../../../data/models/plan_model.dart';
import '../../../data/models/time_slot_model.dart';
import '../../../data/repositories/global_plan_repository.dart';
import '../../../services/local_storage_service.dart';

class GlobalPlansController extends GetxController {
  final GlobalPlanRepository _repo = Get.find<GlobalPlanRepository>();

  // ── State ──────────────────────────────────────────────────────────────
  final RxList<PlanModel>         plans     = <PlanModel>[].obs;
  final RxList<DeliveryAreaModel> areas     = <DeliveryAreaModel>[].obs;
  final RxList<TimeSlotModel>     timeSlots = <TimeSlotModel>[].obs;

  final RxBool isLoadingPlans = true.obs;
  final RxBool isLoadingAreas = true.obs;
  final RxBool isLoadingSlots = true.obs;
  final RxBool isSaving       = false.obs;
  final RxInt  tabIndex       = 0.obs;

  String? get vendorId => LocalStorageService.getVendor()?.id;

  StreamSubscription? _plansSub;
  StreamSubscription? _areasSub;
  StreamSubscription? _slotsSub;

  // ── Plan form controllers ──────────────────────────────────────────────
  final planFormKey       = GlobalKey<FormState>();
  final planNameCtrl      = TextEditingController();
  final planDescCtrl      = TextEditingController();
  final planQtyCtrl       = TextEditingController(text: '1');
  final planPriceCtrl     = TextEditingController();
  final slotLabel = ''.obs;
  final selectedPlanService   = 'milk'.obs;
  final selectedPlanFrequency = 'daily'.obs;
  final selectedPlanUnit      = 'litre'.obs;

  // ── Area form controllers ──────────────────────────────────────────────
  final areaFormKey   = GlobalKey<FormState>();
  final areaNameCtrl  = TextEditingController();
  final areaPinCtrl   = TextEditingController();
  final areaCityCtrl  = TextEditingController();

  // ── Slot form controllers ──────────────────────────────────────────────
  final slotFormKey      = GlobalKey<FormState>();
  final slotLabelCtrl    = TextEditingController();
  final slotStartCtrl    = TextEditingController();
  final slotEndCtrl      = TextEditingController();

  final serviceOptions   = ['milk', 'water', 'newspaper', 'tiffin', 'grocery', 'custom'];
  final frequencyOptions = ['daily', 'alternateDay', 'weekdays', 'weekends', 'weekly', 'custom'];
  final unitOptions      = ['litre', 'packet', 'copy', 'box', 'kg', 'piece'];

  @override
  void onReady() {
    super.onReady();
    _initStreams();
  }

  void _initStreams() {
    if (vendorId == null) return;

    _plansSub = _repo.watchPlans(vendorId!).listen((p) {
      plans.assignAll(p);
      isLoadingPlans.value = false;
    }, onError: (_) => isLoadingPlans.value = false);

    _areasSub = _repo.watchAreas(vendorId!).listen((a) {
      areas.assignAll(a);
      isLoadingAreas.value = false;
    }, onError: (_) => isLoadingAreas.value = false);

    _slotsSub = _repo.watchTimeSlots(vendorId!).listen((s) {
      timeSlots.assignAll(s);
      isLoadingSlots.value = false;
    }, onError: (_) => isLoadingSlots.value = false);
  }

  // ── Computed ───────────────────────────────────────────────────────────
  double get planPreviewPrice {
    final q = double.tryParse(planQtyCtrl.text) ?? 1;
    final p = double.tryParse(planPriceCtrl.text) ?? 0;
    return q * p;
  }

  // ── PLAN CRUD ──────────────────────────────────────────────────────────

  Future<void> savePlan() async {
    if (!planFormKey.currentState!.validate()) return;
    if (vendorId == null) return;
    isSaving.value = true;

    final result = await _repo.createPlan(
      vendorId:    vendorId!,
      name:        planNameCtrl.text.trim(),
      serviceType: selectedPlanService.value,
      frequency:   selectedPlanFrequency.value,
      quantity:    double.tryParse(planQtyCtrl.text) ?? 1,
      unit:        selectedPlanUnit.value,
      pricePerUnit: double.tryParse(planPriceCtrl.text) ?? 0,
      description: planDescCtrl.text.trim(),
    );

    isSaving.value = false;
    if (result.isSuccess) {
      _clearPlanForm();
      Get.back();
      Get.snackbar('✅ Plan Created', '"${planNameCtrl.text}" added successfully.',
          snackPosition: SnackPosition.TOP);
    } else {
      Get.snackbar('Error', 'Failed to create plan. Try again.',
          snackPosition: SnackPosition.TOP);
    }
  }

  Future<void> togglePlanActive(PlanModel plan) async {
    if (vendorId == null) return;
    final updated = plan.copyWith(isActive: !plan.isActive);
    await _repo.updatePlan(vendorId!, updated);
  }

  Future<void> deletePlan(String planId, String planName) async {
    if (vendorId == null) return;
    await _repo.deletePlan(vendorId!, planId);
    Get.snackbar('Deleted', '"$planName" removed.', snackPosition: SnackPosition.TOP);
  }

  void _clearPlanForm() {
    planNameCtrl.clear();
    planDescCtrl.clear();
    planQtyCtrl.text = '1';
    planPriceCtrl.clear();
    slotLabel.value = '';
    selectedPlanService.value   = 'milk';
    selectedPlanFrequency.value = 'daily';
    selectedPlanUnit.value      = 'litre';
  }

  // ── AREA CRUD ──────────────────────────────────────────────────────────

  Future<void> saveArea() async {
    if (!areaFormKey.currentState!.validate()) return;
    if (vendorId == null) return;
    isSaving.value = true;

    final result = await _repo.createArea(
      vendorId: vendorId!,
      name:     areaNameCtrl.text.trim(),
      pincode:  areaPinCtrl.text.trim().isEmpty ? null : areaPinCtrl.text.trim(),
      city:     areaCityCtrl.text.trim().isEmpty ? null : areaCityCtrl.text.trim(),
    );

    isSaving.value = false;
    if (result.isSuccess) {
      _clearAreaForm();
      Get.back();
      Get.snackbar('✅ Area Added', '${areaNameCtrl.text} is now a delivery area.',
          snackPosition: SnackPosition.TOP);
    } else {
      Get.snackbar('Error', 'Failed to add area.', snackPosition: SnackPosition.TOP);
    }
  }

  Future<void> deleteArea(String areaId, String areaName) async {
    if (vendorId == null) return;
    await _repo.deleteArea(vendorId!, areaId);
    Get.snackbar('Removed', '"$areaName" removed from delivery areas.',
        snackPosition: SnackPosition.TOP);
  }

  void _clearAreaForm() {
    areaNameCtrl.clear();
    areaPinCtrl.clear();
    areaCityCtrl.clear();
  }

  // ── TIME SLOT CRUD ─────────────────────────────────────────────────────

  Future<void> saveTimeSlot() async {
    if (!slotFormKey.currentState!.validate()) return;
    if (vendorId == null) return;
    isSaving.value = true;

    final result = await _repo.createTimeSlot(
      vendorId:  vendorId!,
      label:     slotLabelCtrl.text.trim(),
      startTime: slotStartCtrl.text.trim(),
      endTime:   slotEndCtrl.text.trim(),
      sortOrder: timeSlots.length,
    );

    isSaving.value = false;
    if (result.isSuccess) {
      _clearSlotForm();
      Get.back();
      Get.snackbar('✅ Slot Added', '${slotLabelCtrl.text} time slot created.',
          snackPosition: SnackPosition.TOP);
    } else {
      Get.snackbar('Error', 'Failed to add time slot.', snackPosition: SnackPosition.TOP);
    }
  }

  Future<void> deleteTimeSlot(String slotId, String label) async {
    if (vendorId == null) return;
    await _repo.deleteTimeSlot(vendorId!, slotId);
    Get.snackbar('Removed', '"$label" time slot removed.',
        snackPosition: SnackPosition.TOP);
  }

  void _clearSlotForm() {
    slotLabelCtrl.clear();
    slotStartCtrl.clear();
    slotEndCtrl.clear();
  }

  // ── Time picker helper ─────────────────────────────────────────────────
  Future<void> pickTimeSlot(BuildContext context) async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 6, minute: 0),
    );
    if (start == null) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute),
    );
    if (end == null) return;

    final startFmt = start.format(context);
    final endFmt   = end.format(context);
    final label = '$startFmt - $endFmt';

    slotStartCtrl.text = startFmt;
    slotEndCtrl.text   = endFmt;
    slotLabelCtrl.text = label;

    slotLabel.value = label;
  }

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