// lib/data/repositories/delivery_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import '../../services/connectivity_service.dart';
import '../../services/local_storage_service.dart';
import '../models/delivery_model.dart';
import '../models/sync_action_model.dart';

class DeliveryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ConnectivityService _connectivity = Get.find<ConnectivityService>();

  String _col(String vendorId) =>
      '${AppConstants.colVendors}/$vendorId/${AppConstants.colDeliveries}';

  // ── Today's deliveries stream ──────────────────────────────────────────
  Stream<List<DeliveryModel>> watchTodayDeliveries(String vendorId) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end   = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _db
        .collection(_col(vendorId))
        .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('scheduledDate')
        .orderBy('routeOrder')
        .snapshots()
        .map((snap) {
      final deliveries = snap.docs.map((d) => DeliveryModel.fromFirestore(d)).toList();
      LocalStorageService.saveDeliveries(deliveries);
      return deliveries;
    })
        .handleError((e) {
      AppLogger.e('watchTodayDeliveries error', e);
      return LocalStorageService.getTodayDeliveries();
    });
  }

  // ── Local today's deliveries (offline fallback) ────────────────────────
  List<DeliveryModel> getLocalTodayDeliveries() =>
      LocalStorageService.getTodayDeliveries();

  // ── Mark delivery status (most critical offline operation) ─────────────
  Future<Result<void>> updateDeliveryStatus(
      String vendorId,
      DeliveryModel delivery,
      DeliveryStatus newStatus, {
        String? notes,
      }) async {
    final updated = delivery.copyWith(
      statusStr:   newStatus.name,
      deliveredAt: newStatus == DeliveryStatus.delivered ? DateTime.now() : null,
      notes:       notes,
      isSynced:    _connectivity.isOnline.value,
    );

    // 1. Update local cache immediately (UI reflects change instantly)
    await LocalStorageService.saveDelivery(updated);

    final payload = {
      'status':      newStatus.name,
      'deliveredAt': newStatus == DeliveryStatus.delivered
          ? DateTime.now().toIso8601String()
          : null,
      'notes':       notes,
      'updatedAt':   DateTime.now().toIso8601String(),
    };

    if (_connectivity.isOnline.value) {
      try {
        // Use FieldValue.serverTimestamp() for direct Firestore writes
        final firestorePayload = {
          'status':      newStatus.name,
          'deliveredAt': newStatus == DeliveryStatus.delivered
              ? FieldValue.serverTimestamp()
              : null,
          'notes':       notes,
          'updatedAt':   FieldValue.serverTimestamp(),
        };
        await _db.collection(_col(vendorId)).doc(delivery.id).update(firestorePayload);
        // Mark as synced in local cache
        await LocalStorageService.saveDelivery(updated.copyWith(isSynced: true));
        AppLogger.i('Delivery ${delivery.id} marked ${newStatus.name} online');
        return const Result.success(null);
      } catch (e) {
        AppLogger.e('updateDeliveryStatus Firestore error, queuing', e);
        await _enqueueMarkDelivery(vendorId, delivery.id, payload);
        return const Result.success(null);
      }
    } else {
      await _enqueueMarkDelivery(vendorId, delivery.id, payload);
      AppLogger.i('Delivery ${delivery.id} queued offline');
      return const Result.success(null);
    }
  }

  // ── Generate today's delivery schedule from subscriptions ──────────────
  /// Called once per day (ideally via Cloud Function, but can run client-side as fallback)
  Future<Result<int>> generateTodaySchedule(
      String vendorId,
      List<dynamic> subscriptions,
      ) async {
    if (!_connectivity.isOnline.value) {
      return Result.failure(const NetworkFailure('Cannot generate schedule offline.'));
    }

    try {
      final today = DateTime.now();
      final batch = _db.batch();
      int count = 0;

      for (final sub in subscriptions) {
        if (!sub.isActive) continue;
        if (!sub.shouldDeliverOn(today)) continue;

        final id = const Uuid().v4();
        final delivery = DeliveryModel(
          id:              id,
          vendorId:        vendorId,
          customerId:      sub.customerId,
          customerName:    sub.customerName,
          customerAddress: '', // fetch from customer record
          subscriptionId:  sub.id,
          serviceTypeStr:  sub.serviceTypeStr,
          quantity:        sub.quantity,
          unit:            sub.unit,
          amount:          sub.pricePerDelivery,
          scheduledDate:   today,
          deliverySlot:    sub.deliverySlot,
          routeOrder:      count,
          createdAt:       DateTime.now(),
          updatedAt:       DateTime.now(),
        );

        batch.set(
          _db.collection(_col(vendorId)).doc(id),
          delivery.toFirestore(),
        );
        count++;
      }

      await batch.commit();
      AppLogger.i('Generated $count deliveries for today');
      return Result.success(count);
    } catch (e, s) {
      AppLogger.e('generateTodaySchedule error', e, s);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  // ── Place extra order ──────────────────────────────────────────────────
  Future<Result<DeliveryModel>> placeExtraOrder({
    required String vendorId,
    required String customerId,
    required String customerName,
    required String customerAddress,
    required String serviceType,
    required double quantity,
    required String unit,
    required double amount,
    String? notes,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final delivery = DeliveryModel(
      id:              id,
      vendorId:        vendorId,
      customerId:      customerId,
      customerName:    customerName,
      customerAddress: customerAddress,
      serviceTypeStr:  serviceType,
      quantity:        quantity,
      unit:            unit,
      amount:          amount,
      scheduledDate:   now,
      isExtraOrder:    true,
      notes:           notes,
      createdAt:       now,
      updatedAt:       now,
    );

    await LocalStorageService.saveDelivery(delivery);

    if (_connectivity.isOnline.value) {
      await _db.collection(_col(vendorId)).doc(id).set(delivery.toFirestore());
    } else {
      await _enqueuePlaceExtraOrder(vendorId, id, delivery);
    }

    return Result.success(delivery);
  }

  // ── History (paginated) ────────────────────────────────────────────────
  Future<Result<List<DeliveryModel>>> fetchDeliveryHistory(
      String vendorId, {
        DateTime? startDate,
        DateTime? endDate,
        String? customerId,
        String? status,
        DocumentSnapshot? lastDoc,
      }) async {
    try {
      var query = _db
          .collection(_col(vendorId))
          .orderBy('scheduledDate', descending: true)
          .limit(AppConstants.pageSize);

      if (startDate != null) {
        query = query.where('scheduledDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('scheduledDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      if (customerId != null) {
        query = query.where('customerId', isEqualTo: customerId);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snap = await query.get();
      return Result.success(
          snap.docs.map((d) => DeliveryModel.fromFirestore(d)).toList());
    } catch (e) {
      AppLogger.e('fetchDeliveryHistory error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  // ── Sync queue helpers ─────────────────────────────────────────────────
  Future<void> _enqueueMarkDelivery(
      String vendorId, String deliveryId, Map<String, dynamic> payload) async {
    final action = SyncActionModel(
      id:            const Uuid().v4(),
      actionTypeStr: SyncActionType.markDelivery.name,
      collection:    _col(vendorId),
      documentId:    deliveryId,
      payload:       payload,
      createdAt:     DateTime.now(),
    );
    await LocalStorageService.enqueueSyncAction(action);
  }

  Future<void> _enqueuePlaceExtraOrder(
      String vendorId, String id, DeliveryModel d) async {
    final action = SyncActionModel(
      id:            const Uuid().v4(),
      actionTypeStr: SyncActionType.placeExtraOrder.name,
      collection:    _col(vendorId),
      documentId:    id,
      payload:       d.toFirestore(),
      createdAt:     DateTime.now(),
    );
    await LocalStorageService.enqueueSyncAction(action);
  }
}