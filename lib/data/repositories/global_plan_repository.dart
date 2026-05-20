// lib/data/repositories/global_plan_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import '../models/delivery_area_model.dart';
import '../models/plan_model.dart';
import '../models/time_slot_model.dart';

class GlobalPlanRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection paths ───────────────────────────────────────────────────
  String _plansCol(String vendorId) =>
      '${AppConstants.colVendors}/$vendorId/${AppConstants.colPlans}';

  String _areasCol(String vendorId) =>
      '${AppConstants.colVendors}/$vendorId/${AppConstants.colAreas}';

  String _slotsCol(String vendorId) =>
      '${AppConstants.colVendors}/$vendorId/${AppConstants.colTimeSlots}';

  // ══════════════════════════════════════════════════════════════════════
  // PLANS
  // ══════════════════════════════════════════════════════════════════════

  Stream<List<PlanModel>> watchPlans(String vendorId) {
    return _db
        .collection(_plansCol(vendorId))
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      final data = snapshot.docs
          .map((doc) => PlanModel.fromFirestore(doc))
          .where((e) => e.isActive)
          .toList();

      return data;
    }).handleError((e) {
      AppLogger.e('watchPlans error', e);
      return <PlanModel>[];
    });
  }

  Future<Result<List<PlanModel>>> fetchPlans(String vendorId) async {
    try {
      final snap = await _db.collection(_plansCol(vendorId)).get();

      final data = snap.docs
          .map((d) => PlanModel.fromFirestore(d))
          .where((e) => e.isActive)
          .toList();

      return Result.success(data);
    } catch (e) {
      AppLogger.e('fetchPlans error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  Future<Result<PlanModel>> createPlan({
    required String vendorId,
    required String name,
    required String serviceType,
    required String frequency,
    required double quantity,
    required String unit,
    required double pricePerUnit,
    String description = '',
  }) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now();

      final plan = PlanModel(
        id: id,
        vendorId: vendorId,
        name: name,
        serviceType: serviceType,
        frequencyStr: frequency,
        quantity: quantity,
        unit: unit,
        pricePerUnit: pricePerUnit,
        pricePerDelivery: quantity * pricePerUnit,
        description: description,
        createdAt: now,
        updatedAt: now,
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

  Future<Result<void>> updatePlan(
      String vendorId,
      PlanModel plan,
      ) async {
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

  Future<Result<void>> deletePlan(
      String vendorId,
      String planId,
      ) async {
    try {
      await _db
          .collection(_plansCol(vendorId))
          .doc(planId)
          .update({
        'isActive': false,
      });

      return const Result.success(null);
    } catch (e) {
      AppLogger.e('deletePlan error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // DELIVERY AREAS
  // ══════════════════════════════════════════════════════════════════════

  Stream<List<DeliveryAreaModel>> watchAreas(String vendorId) {
    return _db
        .collection(_areasCol(vendorId))
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      final data = snapshot.docs
          .map((doc) => DeliveryAreaModel.fromFirestore(doc))
          .where((e) => e.isActive)
          .toList();

      return data;
    }).handleError((e) {
      AppLogger.e('watchAreas error', e);
      return <DeliveryAreaModel>[];
    });
  }

  Future<Result<List<DeliveryAreaModel>>> fetchAreas(
      String vendorId,
      ) async {
    try {
      final snap = await _db
          .collection(_areasCol(vendorId))
          .get();

      final data = snap.docs
          .map((d) => DeliveryAreaModel.fromFirestore(d))
          .where((e) => e.isActive)
          .toList();

      return Result.success(data);
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

  Future<Result<void>> deleteArea(
      String vendorId,
      String areaId,
      ) async {
    try {
      await _db
          .collection(_areasCol(vendorId))
          .doc(areaId)
          .update({
        'isActive': false,
      });

      return const Result.success(null);
    } catch (e) {
      AppLogger.e('deleteArea error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // TIME SLOTS
  // ══════════════════════════════════════════════════════════════════════

  Stream<List<TimeSlotModel>> watchTimeSlots(String vendorId) {
    return _db
        .collection(_slotsCol(vendorId))
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
      final data = snapshot.docs
          .map((doc) => TimeSlotModel.fromFirestore(doc))
          .where((e) => e.isActive)
          .toList();

      return data;
    }).handleError((e) {
      AppLogger.e('watchTimeSlots error', e);
      return <TimeSlotModel>[];
    });
  }

  Future<Result<List<TimeSlotModel>>> fetchTimeSlots(
      String vendorId,
      ) async {
    try {
      final snap = await _db
          .collection(_slotsCol(vendorId))
          .orderBy('sortOrder')
          .get();

      final data = snap.docs
          .map((d) => TimeSlotModel.fromFirestore(d))
          .where((e) => e.isActive)
          .toList();

      return Result.success(data);
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
    try {
      final id = const Uuid().v4();

      final slot = TimeSlotModel(
        id: id,
        vendorId: vendorId,
        label: label,
        startTime: startTime,
        endTime: endTime,
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

  Future<Result<void>> deleteTimeSlot(
      String vendorId,
      String slotId,
      ) async {
    try {
      await _db
          .collection(_slotsCol(vendorId))
          .doc(slotId)
          .update({
        'isActive': false,
      });

      return const Result.success(null);
    } catch (e) {
      AppLogger.e('deleteTimeSlot error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }
}