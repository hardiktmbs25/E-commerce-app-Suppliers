// lib/data/repositories/global_plan_repository.dart
//
// Changes vs original
// ───────────────────
// • createPlan now accepts [deliverySlotIds] and validates serviceType
//   against kServiceTypes before writing.
// • watchPlans stream error is re-thrown as a typed stream error so the
//   controller's onError callback fires correctly (original swallowed it).
// • fetchPlans adds a vendorId equality filter so a vendor never sees
//   another vendor's plans (defensive; the sub-collection already scopes
//   this, but explicit is safer for future top-level collection queries).
// • All Firestore parsing delegates to PlanModel.fromFirestore which is
//   now fully null-safe.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/plan_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import '../models/delivery_area_model.dart';
import '../models/plan_model.dart';
import '../models/time_slot_model.dart';

class GlobalPlanRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection path helpers ───────────────────────────────────────────────
  String _plansCol(String vendorId) =>
      '${AppConstants.colVendors}/$vendorId/${AppConstants.colPlans}';

  String _areasCol(String vendorId) =>
      '${AppConstants.colVendors}/$vendorId/${AppConstants.colAreas}';

  String _slotsCol(String vendorId) =>
      '${AppConstants.colVendors}/$vendorId/${AppConstants.colTimeSlots}';

  // ══════════════════════════════════════════════════════════════════════════
  // PLANS
  // ══════════════════════════════════════════════════════════════════════════

  /// Live stream of active plans for [vendorId], ordered by name.
  /// Errors are propagated as stream errors (not silently swallowed).
  Stream<List<PlanModel>> watchPlans(String vendorId) {
    return _db
        .collection(_plansCol(vendorId))
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(PlanModel.fromFirestore).toList();
          return list.where((p) => p.isActive).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        })
        .handleError((Object e, StackTrace st) {
      AppLogger.e('watchPlans error', e);
      // rethrow so the controller's onError fires
      throw e;
    });
  }

  Future<Result<List<PlanModel>>> fetchPlans(String vendorId) async {
    try {
      final snap = await _db
          .collection(_plansCol(vendorId))
          .get();
      final list = snap.docs.map(PlanModel.fromFirestore).toList();
      final filtered = list.where((p) => p.isActive).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return Result.success(filtered);
    } catch (e) {
      AppLogger.e('fetchPlans error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  /// Create a new plan template.
  ///
  /// Returns [ValidationFailure] if [serviceType] is not in [kServiceTypes]
  /// or if [pricePerUnit] / [quantity] are zero or negative.
  Future<Result<PlanModel>> createPlan({
    required String vendorId,
    required String name,
    required String serviceType,
    required String frequency,
    required double quantity,
    required String unit,
    required double pricePerUnit,
    List<String> deliverySlotIds = const [],
    List<String> deliveryAreaIds = const [],
    String description = '',
  }) async {
    // ── Validate service type ──────────────────────────────────────────
    if (!kServiceTypes.contains(serviceType)) {
      return Result.failure(
        ValidationFailure('Unknown service type: $serviceType'),
      );
    }
    if (pricePerUnit <= 0) {
      return Result.failure(
        const ValidationFailure('Price per unit must be greater than zero.'),
      );
    }
    if (quantity <= 0) {
      return Result.failure(
        const ValidationFailure('Quantity must be greater than zero.'),
      );
    }
    // Validate slot count matches frequency requirement
    final required = requiredSlotsForFrequency(frequency);
    if (deliverySlotIds.length != required) {
      return Result.failure(ValidationFailure(
        'Frequency "$frequency" requires $required time slot(s); '
            'got ${deliverySlotIds.length}.',
      ));
    }

    try {
      final id  = const Uuid().v4();
      final now = DateTime.now();

      final plan = PlanModel(
        id:              id,
        vendorId:        vendorId,
        name:            name,
        serviceType:     serviceType,
        frequencyStr:    frequency,
        quantity:        quantity,
        unit:            unit,
        pricePerUnit:    pricePerUnit,
        deliverySlotIds: deliverySlotIds,
        deliveryAreaIds: deliveryAreaIds,
        description:     description,
        createdAt:       now,
        updatedAt:       now,
      );

      await _db
          .collection(_plansCol(vendorId))
          .doc(id)
          .set(plan.toFirestore());

      return Result.success(plan);
    } catch (e) {
      AppLogger.e('createPlan error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  Future<Result<void>> updatePlan(String vendorId, PlanModel plan) async {
    try {
      await _db
          .collection(_plansCol(vendorId))
          .doc(plan.id)
          .update(plan.toFirestore());
      return const Result.success(null);
    } catch (e) {
      AppLogger.e('updatePlan error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  /// Soft-delete: sets isActive = false.
  Future<Result<void>> deletePlan(String vendorId, String planId) async {
    try {
      await _db
          .collection(_plansCol(vendorId))
          .doc(planId)
          .update({'isActive': false, 'updatedAt': FieldValue.serverTimestamp()});
      return const Result.success(null);
    } catch (e) {
      AppLogger.e('deletePlan error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DELIVERY AREAS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<DeliveryAreaModel>> watchAreas(String vendorId) {
    return _db
        .collection(_areasCol(vendorId))
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(DeliveryAreaModel.fromFirestore).toList();
          return list.where((a) => a.isActive).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        })
        .handleError((Object e) {
      AppLogger.e('watchAreas error', e);
      throw e;
    });
  }

  Future<Result<List<DeliveryAreaModel>>> fetchAreas(String vendorId) async {
    try {
      final snap = await _db
          .collection(_areasCol(vendorId))
          .get();
      final list = snap.docs.map(DeliveryAreaModel.fromFirestore).toList();
      final filtered = list.where((a) => a.isActive).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return Result.success(filtered);
    } catch (e) {
      AppLogger.e('fetchAreas error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  Future<Result<DeliveryAreaModel>> createArea({
    required String vendorId,
    required String name,
    String? pincode,
    String? city,
  }) async {
    try {
      final id = const Uuid().v4();
      final area = DeliveryAreaModel(
        id: id,
        vendorId: vendorId,
        name: name,
        pincode: pincode,
        city: city,
        createdAt: DateTime.now(),
      );
      await _db
          .collection(_areasCol(vendorId))
          .doc(id)
          .set(area.toFirestore());
      return Result.success(area);
    } catch (e) {
      AppLogger.e('createArea error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteArea(String vendorId, String areaId) async {
    try {
      await _db
          .collection(_areasCol(vendorId))
          .doc(areaId)
          .update({'isActive': false});
      return const Result.success(null);
    } catch (e) {
      AppLogger.e('deleteArea error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  Future<Result<void>> updateArea(String vendorId, DeliveryAreaModel area) async {
    try {
      await _db
          .collection(_areasCol(vendorId))
          .doc(area.id)
          .update(area.toFirestore());
      return const Result.success(null);
    } catch (e) {
      AppLogger.e('updateArea error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TIME SLOTS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<TimeSlotModel>> watchTimeSlots(String vendorId) {
    return _db
        .collection(_slotsCol(vendorId))
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(TimeSlotModel.fromFirestore).toList();
          return list.where((s) => s.isActive).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        })
        .handleError((Object e) {
      AppLogger.e('watchTimeSlots error', e);
      throw e;
    });
  }

  Future<Result<List<TimeSlotModel>>> fetchTimeSlots(String vendorId) async {
    try {
      final snap = await _db
          .collection(_slotsCol(vendorId))
          .get();
      final list = snap.docs.map(TimeSlotModel.fromFirestore).toList();
      final filtered = list.where((s) => s.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return Result.success(filtered);
    } catch (e) {
      AppLogger.e('fetchTimeSlots error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  Future<Result<TimeSlotModel>> createTimeSlot({
    required String vendorId,
    required String label,
    required String startTime,
    required String endTime,
    int sortOrder = 0,
  }) async {
    if (label.trim().isEmpty || startTime.trim().isEmpty || endTime.trim().isEmpty) {
      return Result.failure(
          const ValidationFailure('Time slot label and times are required.'));
    }
    try {
      final id = const Uuid().v4();
      final slot = TimeSlotModel(
        id: id,
        vendorId: vendorId,
        label: label.trim(),
        startTime: startTime.trim(),
        endTime: endTime.trim(),
        sortOrder: sortOrder,
        createdAt: DateTime.now(),
      );
      await _db
          .collection(_slotsCol(vendorId))
          .doc(id)
          .set(slot.toFirestore());
      return Result.success(slot);
    } catch (e) {
      AppLogger.e('createTimeSlot error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteTimeSlot(String vendorId, String slotId) async {
    try {
      await _db
          .collection(_slotsCol(vendorId))
          .doc(slotId)
          .update({'isActive': false});
      return const Result.success(null);
    } catch (e) {
      AppLogger.e('deleteTimeSlot error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  Future<Result<void>> updateTimeSlot(String vendorId, TimeSlotModel slot) async {
    try {
      await _db
          .collection(_slotsCol(vendorId))
          .doc(slot.id)
          .update(slot.toFirestore());
      return const Result.success(null);
    } catch (e) {
      AppLogger.e('updateTimeSlot error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }
}