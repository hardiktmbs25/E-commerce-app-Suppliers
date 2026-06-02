// lib/services/delivery_generation_service.dart
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../data/models/delivery_model.dart';
import '../data/models/sync_action_model.dart';
import 'connectivity_service.dart';
import 'local_storage_service.dart';

class DeliveryGenerationService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ConnectivityService _connectivity = Get.find<ConnectivityService>();

  String _deliveriesCol(String vid) =>
      '${AppConstants.colVendors}/$vid/${AppConstants.colDeliveries}';

  // ─────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────

  /// Creates deliveries for every active subscription that has [targetSlot]
  /// in its effectiveSlots, scheduled for [date].
  ///
  /// Uses deterministic IDs (subId_dateKey_safeSlot) so re-running is safe —
  /// already-existing deliveries are silently skipped.
  Future<int> generateForDateAndSlot(
      String vendorId,
      DateTime date,
      String targetSlot,
      ) async {
    final subscriptions = LocalStorageService.getSubscriptions()
        .where((s) => s.isActive)
        .toList();

    if (subscriptions.isEmpty) return 0;

    final customerMap = {
      for (final c in LocalStorageService.getCustomers()) c.id: c,
    };

    int count = 0;
    final batch = _db.batch();
    final List<DeliveryModel> localToSave = [];

    for (final sub in subscriptions) {
      if (!sub.shouldDeliverOn(date)) continue;
      if (!sub.effectiveSlots.contains(targetSlot)) continue;

      final customer = customerMap[sub.customerId];
      if (customer != null && customer.statusStr == 'inactive') continue;

      // Deterministic ID — prevents duplicates if vendor taps Generate twice
      final dateKey    = _dateKey(date);
      final safeSlot   = targetSlot.replaceAll(' ', '_').replaceAll(':', '');
      final deliveryId = '${sub.id}_${dateKey}_$safeSlot';

      // Skip if already exists locally
      if (_existsLocally(sub.id, date, targetSlot)) continue;

      final delivery = DeliveryModel(
        id:              deliveryId,
        vendorId:        vendorId,
        customerId:      sub.customerId,
        customerName:    sub.customerName,
        customerAddress: customer?.address ?? '',
        subscriptionId:  sub.id,
        serviceTypeStr:  sub.serviceTypeStr,
        quantity:        sub.quantity,
        unit:            sub.unit,
        amount:          sub.pricePerDelivery,
        scheduledDate:   _slotDateTime(date, targetSlot),
        deliverySlot:    targetSlot,
        routeOrder:      0,
        statusStr:       DeliveryStatus.pending.name,
        isExtraOrder:    false,
        isSynced:        _connectivity.isOnline.value,
        createdAt:       DateTime.now(),
        updatedAt:       DateTime.now(),
        billGenerated:   false,
        invoiceId:       null,
      );

      localToSave.add(delivery);

      if (_connectivity.isOnline.value) {
        batch.set(
          _db.collection(_deliveriesCol(vendorId)).doc(delivery.id),
          delivery.toFirestore(),
          SetOptions(merge: true),
        );
      } else {
        _enqueueOffline(vendorId, delivery);
      }
      count++;
    }

    if (_connectivity.isOnline.value && count > 0) {
      try {
        await batch.commit();
      } catch (e) {
        AppLogger.e('GenerationService: batch commit failed — queuing offline', e);
        for (final d in localToSave) {
          _enqueueOffline(vendorId, d..copyWith(isSynced: false));
        }
      }
    }

    for (final d in localToSave) {
      await LocalStorageService.saveDelivery(d);
    }

    if (count > 0) {
      AppLogger.i('GenerationService: +$count deliveries  slot=$targetSlot  date=${_dateKey(date)}');
    }
    return count;
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  bool _existsLocally(String subscriptionId, DateTime date, String slot) =>
      LocalStorageService.getDeliveries().any((d) =>
      d.subscriptionId == subscriptionId &&
          d.deliverySlot == slot &&
          _sameDay(d.scheduledDate, date));

  void _enqueueOffline(String vendorId, DeliveryModel d) {
    LocalStorageService.enqueueSyncAction(SyncActionModel(
      id:            const Uuid().v4(),
      actionTypeStr: SyncActionType.placeExtraOrder.name,
      collection:    _deliveriesCol(vendorId),
      documentId:    d.id,
      payload:       d.toFirestore(),
      createdAt:     DateTime.now(),
    ));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Parses "03:00 PM" → DateTime on [baseDate] at 15:00.
  DateTime _slotDateTime(DateTime baseDate, String slot) {
    final parts = slot.trim().toUpperCase().split(' ');
    if (parts.length != 2) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day, 7, 0);
    }
    final tp     = parts[0].split(':');
    int hour     = int.tryParse(tp[0]) ?? 7;
    int minute   = tp.length > 1 ? (int.tryParse(tp[1]) ?? 0) : 0;
    if (parts[1] == 'PM' && hour != 12) hour += 12;
    if (parts[1] == 'AM' && hour == 12) hour = 0;
    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }
}