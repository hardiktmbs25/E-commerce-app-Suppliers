// lib/data/repositories/subscription_repository.dart
//
// CHANGES:
//  • createSubscription now accepts deliverySlots + startDate params.
//  • Passes deliverySlots to SubscriptionModel and Firestore.
//  • Result<T> kept identical to existing project pattern.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/service_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import '../../services/connectivity_service.dart';
import '../../services/local_storage_service.dart';
import '../models/subscription_model.dart';
import '../models/sync_action_model.dart';

class SubscriptionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ConnectivityService _connectivity = Get.find<ConnectivityService>();

  String _col(String vendorId) =>
      '${AppConstants.colVendors}/$vendorId/${AppConstants.colSubscriptions}';

  // ── Realtime stream ──────────────────────────────────────────────────────
  Stream<List<SubscriptionModel>> watchSubscriptions(String vendorId) {
    return _db
        .collection(_col(vendorId))
        .where('status', whereIn: [
      SubscriptionStatus.active.name,
      SubscriptionStatus.paused.name,
    ])
        .orderBy('customerName')
        .snapshots()
        .map((snap) {
      final subs = snap.docs
          .map((d) => SubscriptionModel.fromFirestore(d))
          .toList();
      LocalStorageService.saveSubscriptions(subs);
      return subs;
    })
        .handleError((e) {
      AppLogger.e('watchSubscriptions error', e);
      return LocalStorageService.getSubscriptions();
    });
  }

  // ── Fetch for customer ───────────────────────────────────────────────────
  Future<Result<List<SubscriptionModel>>> fetchCustomerSubscriptions(
      String vendorId, String customerId) async {
    try {
      final snap = await _db
          .collection(_col(vendorId))
          .where('customerId', isEqualTo: customerId)
          .get();
      return Result.success(
          snap.docs.map((d) => SubscriptionModel.fromFirestore(d)).toList());
    } catch (e) {
      AppLogger.e('fetchCustomerSubscriptions error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  // ── Create ───────────────────────────────────────────────────────────────
  Future<Result<SubscriptionModel>> createSubscription({
    required String vendorId,
    required String customerId,
    required String customerName,
    required String serviceType,
    required String frequency,
    required double quantity,
    required String unit,
    required double pricePerUnit,
    required String deliverySlot,
    List<String> deliverySlots = const [],
    List<int> customDays = const [],
    String? notes,
    DateTime? startDate,
  }) async {
    final id  = const Uuid().v4();
    final now = DateTime.now();
    final start = startDate ?? now;

    // Ensure deliverySlots is never empty
    final effectiveSlots = deliverySlots.isNotEmpty
        ? deliverySlots
        : [deliverySlot.isNotEmpty ? deliverySlot : '07:00 AM'];

    final sub = SubscriptionModel(
      id:               id,
      vendorId:         vendorId,
      customerId:       customerId,
      customerName:     customerName,
      serviceTypeStr:   serviceType,
      frequencyStr:     frequency,
      quantity:         quantity,
      unit:             unit,
      pricePerUnit:     pricePerUnit,
      pricePerDelivery: quantity * pricePerUnit,
      deliverySlot:     effectiveSlots.first,
      deliverySlots:    effectiveSlots,
      startDate:        start,
      customDays:       customDays,
      notes:            notes,
      createdAt:        now,
      updatedAt:        now,
    );

    // Write to local cache immediately (offline-first)
    await LocalStorageService.saveSubscription(sub);

    if (_connectivity.isOnline.value) {
      try {
        await _db.collection(_col(vendorId)).doc(id).set(sub.toFirestore());
        return Result.success(sub);
      } catch (e) {
        AppLogger.e('createSubscription Firestore error – queued', e);
        await _enqueueCreate(vendorId, id, sub);
        return Result.success(sub); // still succeeds offline
      }
    } else {
      await _enqueueCreate(vendorId, id, sub);
      return Result.success(sub);
    }
  }

  // ── Pause ────────────────────────────────────────────────────────────────
  Future<Result<void>> pauseSubscription(
      String vendorId, String subId, DateTime? resumeDate) async {
    return _updateSubscription(vendorId, subId, {
      'status': SubscriptionStatus.paused.name,
      'pausedUntil':
      resumeDate != null ? Timestamp.fromDate(resumeDate) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Resume ───────────────────────────────────────────────────────────────
  Future<Result<void>> resumeSubscription(
      String vendorId, String subId) async {
    return _updateSubscription(vendorId, subId, {
      'status': SubscriptionStatus.active.name,
      'pausedUntil': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Cancel ───────────────────────────────────────────────────────────────
  Future<Result<void>> cancelSubscription(
      String vendorId, String subId) async {
    return _updateSubscription(vendorId, subId, {
      'status': SubscriptionStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  Future<Result<void>> _updateSubscription(
      String vendorId, String subId, Map<String, dynamic> payload) async {
    if (_connectivity.isOnline.value) {
      try {
        await _db.collection(_col(vendorId)).doc(subId).update(payload);
        return const Result.success(null);
      } catch (e) {
        await _enqueueUpdate(vendorId, subId, payload);
        return const Result.success(null);
      }
    } else {
      await _enqueueUpdate(vendorId, subId, payload);
      return const Result.success(null);
    }
  }

  Future<void> _enqueueCreate(
      String vendorId, String id, SubscriptionModel sub) async {
    await LocalStorageService.enqueueSyncAction(SyncActionModel(
      id:            const Uuid().v4(),
      actionTypeStr: SyncActionType.updateSubscription.name,
      collection:    _col(vendorId),
      documentId:    id,
      payload:       sub.toFirestore(),
      createdAt:     DateTime.now(),
    ));
  }

  Future<void> _enqueueUpdate(
      String vendorId, String subId, Map<String, dynamic> payload) async {
    await LocalStorageService.enqueueSyncAction(SyncActionModel(
      id:            const Uuid().v4(),
      actionTypeStr: SyncActionType.updateSubscription.name,
      collection:    _col(vendorId),
      documentId:    subId,
      payload:       payload,
      createdAt:     DateTime.now(),
    ));
  }
}