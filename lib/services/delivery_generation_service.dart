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

  /// Generates both today's and tomorrow's deliveries in advance.
  /// Runs on app startup and scheduled 12 AM job.
  Future<int> generateTodayAndTomorrow(String vendorId) async {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    int generatedToday = await generateForDate(vendorId, today);
    int generatedTomorrow = await generateForDate(vendorId, tomorrow);

    return generatedToday + generatedTomorrow;
  }

  /// Generates deliveries for a specific calendar day.
  /// Validates duplicate protection using local cache lookups.
  Future<int> generateForDate(String vendorId, DateTime date) async {
    final subscriptions = LocalStorageService.getSubscriptions()
        .where((s) => s.isActive)
        .toList();

    if (subscriptions.isEmpty) return 0;

    final customerMap = {
      for (final c in LocalStorageService.getCustomers())
        c.id: c,
    };

    int count = 0;
    final batch = _db.batch();
    final List<DeliveryModel> localToSave = [];

    // Keep track of route index sizing
    int routeOrder = LocalStorageService.getDeliveries()
        .where((d) => _isSameDate(d.scheduledDate, date))
        .length;

    for (final sub in subscriptions) {
      if (!sub.shouldDeliverOn(date)) {
        continue;
      }

      final customer = customerMap[sub.customerId];
      final address = customer?.address ?? '';

      // Skip generation if subscription is inactive or customer status is inactive
      if (customer != null && customer.statusStr == 'inactive') {
        continue;
      }

      for (final slot in sub.effectiveSlots) {
        // 1. DUPLICATE PROTECTION: skip if delivery already generated in cache
        final exists = _checkDeliveryExistsLocally(sub.id, date, slot);
        if (exists) {
          continue;
        }

        final slotTime = _slotToDateTime(date, slot);

        final delivery = DeliveryModel(
          id: const Uuid().v4(),
          vendorId: vendorId,
          customerId: sub.customerId,
          customerName: sub.customerName,
          customerAddress: address,
          subscriptionId: sub.id,
          serviceTypeStr: sub.serviceTypeStr,
          quantity: sub.quantity,
          unit: sub.unit,
          amount: sub.pricePerDelivery,
          scheduledDate: slotTime,
          deliverySlot: slot,
          routeOrder: routeOrder++,
          statusStr: DeliveryStatus.pending.name,
          isExtraOrder: false,
          isSynced: _connectivity.isOnline.value,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          billGenerated: false,
          invoiceId: null,
        );

        localToSave.add(delivery);

        if (_connectivity.isOnline.value) {
          batch.set(
            _db.collection(_deliveriesCol(vendorId)).doc(delivery.id),
            delivery.toFirestore(),
          );
        } else {
          // Save offline action
          _enqueueOfflineCreate(vendorId, delivery);
        }
        count++;
      }
    }

    // 2. Commit batch if online
    if (_connectivity.isOnline.value && count > 0) {
      try {
        await batch.commit();
      } catch (e) {
        AppLogger.e('DeliveryGenerationService: Firestore batch commit failed. Falling back to offline queue', e);
        for (final d in localToSave) {
          _enqueueOfflineCreate(vendorId, d..copyWith(isSynced: false));
        }
      }
    }

    // 3. Save generated items in Hive cache
    for (final d in localToSave) {
      await LocalStorageService.saveDelivery(d);
    }

    if (count > 0) {
      AppLogger.i('Generated $count deliveries for date: ${_formatDateKey(date)}');
    }
    return count;
  }

  /// Generates deliveries specifically for one slot on a specific date.
  Future<int> generateForDateAndSlot(String vendorId, DateTime date, String targetSlot) async {
    final subscriptions = LocalStorageService.getSubscriptions()
        .where((s) => s.isActive)
        .toList();

    if (subscriptions.isEmpty) return 0;

    final customerMap = {
      for (final c in LocalStorageService.getCustomers())
        c.id: c,
    };

    int count = 0;
    final batch = _db.batch();
    final List<DeliveryModel> localToSave = [];

    // Filter subscriptions that have THIS specific slot
    for (final sub in subscriptions) {
      if (!sub.shouldDeliverOn(date)) continue;
      if (!sub.effectiveSlots.contains(targetSlot)) continue;

      final customer = customerMap[sub.customerId];
      if (customer != null && customer.statusStr == 'inactive') continue;

      // Duplicate protection
      if (_checkDeliveryExistsLocally(sub.id, date, targetSlot)) continue;

      final slotTime = _slotToDateTime(date, targetSlot);
      final delivery = DeliveryModel(
        id: const Uuid().v4(),
        vendorId: vendorId,
        customerId: sub.customerId,
        customerName: sub.customerName,
        customerAddress: customer?.address ?? '',
        subscriptionId: sub.id,
        serviceTypeStr: sub.serviceTypeStr,
        quantity: sub.quantity,
        unit: sub.unit,
        amount: sub.pricePerDelivery,
        scheduledDate: slotTime,
        deliverySlot: targetSlot,
        routeOrder: 0, // Simplified for auto-generation
        statusStr: DeliveryStatus.pending.name,
        isExtraOrder: false,
        isSynced: _connectivity.isOnline.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        billGenerated: false,
      );

      localToSave.add(delivery);
      if (_connectivity.isOnline.value) {
        batch.set(_db.collection(_deliveriesCol(vendorId)).doc(delivery.id), delivery.toFirestore());
      } else {
        _enqueueOfflineCreate(vendorId, delivery);
      }
      count++;
    }

    if (_connectivity.isOnline.value && count > 0) {
      await batch.commit();
    }

    for (final d in localToSave) {
      await LocalStorageService.saveDelivery(d);
    }

    return count;
  }

  bool _checkDeliveryExistsLocally(String subscriptionId, DateTime date, String slot) {
    final deliveries = LocalStorageService.getDeliveries();
    return deliveries.any((d) =>
        d.subscriptionId == subscriptionId &&
        d.deliverySlot == slot &&
        _isSameDate(d.scheduledDate, date));
  }

  void _enqueueOfflineCreate(String vendorId, DeliveryModel d) {
    LocalStorageService.enqueueSyncAction(SyncActionModel(
      id: const Uuid().v4(),
      actionTypeStr: SyncActionType.placeExtraOrder.name, // Maps to a set() sync operation
      collection: _deliveriesCol(vendorId),
      documentId: d.id,
      payload: d.toFirestore(),
      createdAt: DateTime.now(),
    ));
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  DateTime _slotToDateTime(DateTime baseDate, String slot) {
    final cleaned = slot.trim().toUpperCase();
    final parts = cleaned.split(' ');

    if (parts.length != 2) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day, 7, 0);
    }

    final time = parts[0];
    final meridian = parts[1];
    final timeParts = time.split(':');

    int hour = int.tryParse(timeParts[0]) ?? 7;
    int minute = (timeParts.length > 1) ? (int.tryParse(timeParts[1]) ?? 0) : 0;

    if (meridian == 'PM' && hour != 12) {
      hour += 12;
    }
    if (meridian == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }
}
