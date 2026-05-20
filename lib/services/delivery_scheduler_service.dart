// lib/services/delivery_scheduler_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../data/models/delivery_model.dart';
import '../data/models/subscription_model.dart';
import '../services/local_storage_service.dart';

/// Generates ONE delivery per subscription per valid scheduled period.
///
/// Rules:
///   daily        → 1 delivery per calendar day
///   alternateDay → 1 delivery every 2 days (based on startDate diff)
///   weekdays     → 1 delivery Mon–Fri only
///   weekends     → 1 delivery Sat–Sun only
///   weekly       → 1 delivery on the same weekday as startDate, once per week
///   custom       → 1 delivery on selected weekdays only
///
/// A delivery is NEVER created twice for the same subscription on the same
/// calendar day, regardless of how many times refresh is called.
class DeliverySchedulerService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxBool isGenerating = false.obs;

  String _deliveriesCol(String vendorId) =>
      '${AppConstants.colVendors}/$vendorId/${AppConstants.colDeliveries}';

  // Key stored in Hive settings to track last-generated date
  static String _lastGenKey(String vendorId) => 'scheduler_last_gen_$vendorId';

  // ── Public API ─────────────────────────────────────────────────────────

  /// Called on app open / delivery screen open.
  /// Skips entirely if already run today — safe to call multiple times.
  Future<void> runIfNeeded(String vendorId) async {
    final today = _dateKey(DateTime.now());
    final lastGen = LocalStorageService.getSetting<String>(_lastGenKey(vendorId));
    if (lastGen == today) {
      AppLogger.i('Scheduler: already ran for $today — skipping.');
      return;
    }
    await _generateForDate(vendorId, DateTime.now());
  }

  /// Called immediately after a NEW subscription is saved.
  /// Creates today's delivery for that subscription only if:
  ///   1. The subscription should deliver today (frequency check)
  ///   2. No delivery already exists for it today (duplicate check)
  Future<void> generateForNewSubscription(
      String vendorId, SubscriptionModel sub, String customerAddress) async {
    final today = DateTime.now();
    if (!sub.isActive || !sub.shouldDeliverOn(today)) return;

    // Local duplicate check first (fast, no Firestore call)
    if (_localDeliveryExistsForSub(sub.id, today)) {
      AppLogger.i('Scheduler: local delivery already exists for sub ${sub.id}');
      return;
    }

    // Firestore duplicate check (definitive)
    final exists = await _firestoreDeliveryExistsForSub(vendorId, sub.id, today);
    if (exists) return;

    final routeOrder = LocalStorageService.getTodayDeliveries().length;
    final delivery = _buildDelivery(
      vendorId: vendorId, sub: sub,
      customerAddress: customerAddress,
      date: today, routeOrder: routeOrder,
    );

    try {
      await _db
          .collection(_deliveriesCol(vendorId))
          .doc(delivery.id)
          .set(delivery.toFirestore());
      await LocalStorageService.saveDelivery(delivery);
      AppLogger.i('Scheduler: created delivery for new sub ${sub.id}');
    } catch (e) {
      AppLogger.e('generateForNewSubscription error', e);
    }
  }

  // ── Core generation ────────────────────────────────────────────────────

  Future<int> _generateForDate(String vendorId, DateTime date) async {
    if (isGenerating.value) {
      AppLogger.i('Scheduler: already running, skipping duplicate call.');
      return 0;
    }
    isGenerating.value = true;

    try {
      final subscriptions = LocalStorageService.getSubscriptions();
      if (subscriptions.isEmpty) {
        AppLogger.i('Scheduler: no subscriptions found.');
        _markGeneratedToday(vendorId);
        isGenerating.value = false;
        return 0;
      }

      // Step 1: Get all subscriptionIds that already have a delivery today
      // Check BOTH local cache and Firestore to be bulletproof
      final existingLocal    = _getLocalSubIdsForDate(date);
      final existingFirestore = await _getFirestoreSubIdsForDate(vendorId, date);
      final existingSubIds   = {...existingLocal, ...existingFirestore};

      AppLogger.i('Scheduler: ${existingSubIds.length} subscriptions already '
          'have deliveries for ${_dateKey(date)}');

      // Step 2: Customer address map
      final customerMap = {
        for (final c in LocalStorageService.getCustomers()) c.id: c.address
      };

      // Step 3: Build deliveries for subscriptions that don't have one yet
      final toCreate = <DeliveryModel>[];
      int routeOrder = existingSubIds.length;

      for (final sub in subscriptions) {
        if (!sub.isActive) continue;
        if (!sub.shouldDeliverOn(date)) continue;
        if (existingSubIds.contains(sub.id)) continue; // already exists — skip

        final delivery = _buildDelivery(
          vendorId:        vendorId,
          sub:             sub,
          customerAddress: customerMap[sub.customerId] ?? '',
          date:            date,
          routeOrder:      routeOrder++,
        );
        toCreate.add(delivery);
      }

      if (toCreate.isEmpty) {
        AppLogger.i('Scheduler: nothing new to create for ${_dateKey(date)}.');
        _markGeneratedToday(vendorId);
        isGenerating.value = false;
        return 0;
      }

      // Step 4: Batch write to Firestore (max 500 per batch)
      final chunks = _chunk(toCreate, 499);
      for (final chunk in chunks) {
        final batch = _db.batch();
        for (final d in chunk) {
          batch.set(_db.collection(_deliveriesCol(vendorId)).doc(d.id), d.toFirestore());
        }
        await batch.commit();
        // Also save locally
        for (final d in chunk) {
          await LocalStorageService.saveDelivery(d);
        }
      }

      _markGeneratedToday(vendorId);
      AppLogger.i('Scheduler: created ${toCreate.length} new deliveries '
          'for ${_dateKey(date)}');
      isGenerating.value = false;
      return toCreate.length;
    } catch (e) {
      AppLogger.e('_generateForDate error', e);
      isGenerating.value = false;
      return 0;
    }
  }

  // ── Duplicate detection ────────────────────────────────────────────────

  /// Check local Hive cache for subscriptionIds that already have a delivery today.
  Set<String> _getLocalSubIdsForDate(DateTime date) {
    final all = LocalStorageService.getTodayDeliveries();
    return all
        .where((d) => d.subscriptionId != null && !d.isExtraOrder)
        .map((d) => d.subscriptionId!)
        .toSet();
  }

  /// Check Firestore for subscriptionIds that already have a delivery today.
  Future<Set<String>> _getFirestoreSubIdsForDate(
      String vendorId, DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snap = await _db
          .collection(_deliveriesCol(vendorId))
          .where('scheduledDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('scheduledDate',
          isLessThanOrEqualTo: Timestamp.fromDate(end))
          .where('isExtraOrder', isEqualTo: false)
          .get();

      return snap.docs
          .map((d) => (d.data()['subscriptionId'] as String?) ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      AppLogger.e('_getFirestoreSubIdsForDate error', e);
      return {};
    }
  }

  bool _localDeliveryExistsForSub(String subId, DateTime date) {
    return LocalStorageService.getTodayDeliveries()
        .any((d) => d.subscriptionId == subId && !d.isExtraOrder);
  }

  Future<bool> _firestoreDeliveryExistsForSub(
      String vendorId, String subId, DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snap = await _db
          .collection(_deliveriesCol(vendorId))
          .where('subscriptionId', isEqualTo: subId)
          .where('scheduledDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('scheduledDate',
          isLessThanOrEqualTo: Timestamp.fromDate(end))
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ── Build delivery model ───────────────────────────────────────────────

  DeliveryModel _buildDelivery({
    required String vendorId,
    required SubscriptionModel sub,
    required String customerAddress,
    required DateTime date,
    required int routeOrder,
  }) {
    final now       = DateTime.now();
    final scheduled = DateTime(date.year, date.month, date.day, 7, 0);

    return DeliveryModel(
      id:              const Uuid().v4(),
      vendorId:        vendorId,
      customerId:      sub.customerId,
      customerName:    sub.customerName,
      customerAddress: customerAddress,
      subscriptionId:  sub.id,
      serviceTypeStr:  sub.serviceTypeStr,
      statusStr:       DeliveryStatus.pending.name,
      quantity:        sub.quantity,
      unit:            sub.unit,
      amount:          sub.pricePerDelivery,
      scheduledDate:   scheduled,
      deliverySlot:    sub.deliverySlot,
      routeOrder:      routeOrder,
      isExtraOrder:    false,
      isSynced:        true,
      createdAt:       now,
      updatedAt:       now,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  void _markGeneratedToday(String vendorId) {
    LocalStorageService.saveSetting(
        _lastGenKey(vendorId), _dateKey(DateTime.now()));
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }
}