// lib/services/delivery_scheduler_service.dart
import 'dart:async';
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
/// Schedule logic per frequency:
///   daily        → every calendar day
///   alternateDay → every 2 days from startDate
///   weekdays     → Mon–Fri only
///   weekends     → Sat–Sun only
///   weekly       → once per week on same weekday as startDate
///   custom       → only on selected weekdays (0=Mon … 6=Sun)
///
/// Never creates duplicate deliveries — checks both local Hive cache
/// AND Firestore before writing.
///
/// Also handles next-day generation: when app opens or midnight passes,
/// runs automatically for today if not yet done.
class DeliverySchedulerService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxBool  isGenerating = false.obs;
  Timer?        _midnightTimer;

  String _deliveriesCol(String vid) =>
      '${AppConstants.colVendors}/$vid/${AppConstants.colDeliveries}';

  static String _lastGenKey(String vid) => 'scheduler_last_gen_$vid';

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void onReady() {
    super.onReady();
    _scheduleMidnightRun();
  }

  /// Schedule a timer that fires at midnight to auto-generate next day's deliveries.
  void _scheduleMidnightRun() {
    _midnightTimer?.cancel();
    final now      = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1); // next midnight
    final diff     = midnight.difference(now);

    AppLogger.i('Scheduler: next midnight run in ${diff.inHours}h ${diff.inMinutes % 60}m');

    _midnightTimer = Timer(diff, () async {
      final vendorId = LocalStorageService.vendorId;
      if (vendorId != null) {
        AppLogger.i('Scheduler: midnight timer fired — generating for new day');
        await _generateForDate(vendorId, DateTime.now());
      }
      _scheduleMidnightRun(); // reschedule for next midnight
    });
  }

  // ── Public API ─────────────────────────────────────────────────────────

  /// Safe to call on every app open / screen open.
  /// Runs only once per calendar day per vendor. Skips if already done.
  Future<void> runIfNeeded(String vendorId) async {
    final today   = _dateKey(DateTime.now());
    final lastGen = LocalStorageService.getSetting<String>(_lastGenKey(vendorId));
    if (lastGen == today) {
      AppLogger.i('Scheduler: already ran for $today — skipping.');
      return;
    }
    await _generateForDate(vendorId, DateTime.now());
  }

  /// Called immediately after a NEW subscription is saved.
  /// Creates today's delivery for that subscription only if it should deliver today.
  Future<void> generateForNewSubscription(
      String vendorId, SubscriptionModel sub, String customerAddress) async {
    final today = DateTime.now();
    if (!sub.isActive || !sub.shouldDeliverOn(today)) return;

    if (_localDeliveryExistsForSub(sub.id)) return;
    final exists = await _firestoreDeliveryExistsForSub(vendorId, sub.id, today);
    if (exists) return;

    final routeOrder = LocalStorageService.getTodayDeliveries().length;
    final delivery   = _buildDelivery(
      vendorId: vendorId, sub: sub,
      customerAddress: customerAddress,
      date: today, routeOrder: routeOrder,
    );

    try {
      final batch = _db.batch();
      batch.set(
        _db.collection(_deliveriesCol(vendorId)).doc(delivery.id),
        delivery.toFirestore(),
      );
      // Update subscription's nextDeliveryDate
      final nextDate = _nextDeliveryDate(sub, today);
      batch.update(
        _db.collection(_subscriptionsCol(vendorId)).doc(sub.id),
        {
          'nextDeliveryDate': Timestamp.fromDate(nextDate),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      await batch.commit();
      await LocalStorageService.saveDelivery(delivery);
      AppLogger.i('Scheduler: created delivery for new sub ${sub.id}');
    } catch (e) {
      AppLogger.e('generateForNewSubscription error', e);
    }
  }

  // ── Core generation ────────────────────────────────────────────────────

  Future<int> _generateForDate(String vendorId, DateTime date) async {
    if (isGenerating.value) return 0;
    isGenerating.value = true;

    try {
      final subscriptions = LocalStorageService.getSubscriptions()
          .where((s) => s.isActive)
          .toList();

      if (subscriptions.isEmpty) {
        _markGeneratedToday(vendorId);
        isGenerating.value = false;
        return 0;
      }

      // Dual-layer duplicate check
      final existingLocal     = _getLocalSubIdsForDate(date);
      final existingFirestore = await _getFirestoreSubIdsForDate(vendorId, date);
      final existingSubIds    = {...existingLocal, ...existingFirestore};

      final customerMap = {
        for (final c in LocalStorageService.getCustomers()) c.id: c.address
      };

      final toCreate = <DeliveryModel>[];
      int routeOrder = existingSubIds.length;

      for (final sub in subscriptions) {
        // Skip if endDate passed
        if (sub.endDate != null &&
            date.isAfter(sub.endDate!.add(const Duration(days: 1)))) continue;

        // Skip if before startDate
        if (date.isBefore(DateTime(
            sub.startDate.year, sub.startDate.month, sub.startDate.day))) continue;

        if (!sub.shouldDeliverOn(date)) continue;
        if (existingSubIds.contains(sub.id)) continue;

        toCreate.add(_buildDelivery(
          vendorId:        vendorId,
          sub:             sub,
          customerAddress: customerMap[sub.customerId] ?? '',
          date:            date,
          routeOrder:      routeOrder++,
        ));
      }

      if (toCreate.isEmpty) {
        AppLogger.i('Scheduler: no new deliveries needed for ${_dateKey(date)}');
        _markGeneratedToday(vendorId);
        isGenerating.value = false;
        return 0;
      }

      // Batch write — Firestore max 500 per batch
      for (final chunk in _chunk(toCreate, 499)) {
        final batch = _db.batch();
        for (final d in chunk) {
          batch.set(
            _db.collection(_deliveriesCol(vendorId)).doc(d.id),
            d.toFirestore(),
          );
        }
        await batch.commit();
        for (final d in chunk) {
          await LocalStorageService.saveDelivery(d);
        }
      }

      // Update nextDeliveryDate on each subscription
      await _updateNextDeliveryDates(vendorId, subscriptions, date);

      _markGeneratedToday(vendorId);
      AppLogger.i(
          'Scheduler: created ${toCreate.length} deliveries for ${_dateKey(date)}');
      isGenerating.value = false;
      return toCreate.length;
    } catch (e) {
      AppLogger.e('_generateForDate error', e);
      isGenerating.value = false;
      return 0;
    }
  }

  // ── nextDeliveryDate management ────────────────────────────────────────

  /// Calculates the next delivery date after [fromDate] for a subscription.
  DateTime _nextDeliveryDate(SubscriptionModel sub, DateTime fromDate) {
    var next = fromDate.add(const Duration(days: 1));
    // Look up to 14 days ahead to find next valid date
    for (int i = 0; i < 14; i++) {
      if (sub.shouldDeliverOn(next)) return next;
      next = next.add(const Duration(days: 1));
    }
    return next; // fallback
  }

  Future<void> _updateNextDeliveryDates(
      String vendorId, List<SubscriptionModel> subs, DateTime today) async {
    try {
      // Update in batches of 499
      for (final chunk in _chunk(subs, 499)) {
        final batch = _db.batch();
        for (final sub in chunk) {
          if (!sub.shouldDeliverOn(today)) continue;
          final next = _nextDeliveryDate(sub, today);
          batch.update(
            _db.collection(_subscriptionsCol(vendorId)).doc(sub.id),
            {
              'nextDeliveryDate':    Timestamp.fromDate(next),
              'completedDeliveries': FieldValue.increment(0), // touch updatedAt
              'updatedAt':           FieldValue.serverTimestamp(),
            },
          );
        }
        await batch.commit();
      }
    } catch (e) {
      AppLogger.e('_updateNextDeliveryDates error', e);
    }
  }

  // ── Duplicate detection ────────────────────────────────────────────────

  Set<String> _getLocalSubIdsForDate(DateTime date) {
    return LocalStorageService.getTodayDeliveries()
        .where((d) => d.subscriptionId != null && !d.isExtraOrder)
        .map((d) => d.subscriptionId!)
        .toSet();
  }

  bool _localDeliveryExistsForSub(String subId) {
    return LocalStorageService.getTodayDeliveries()
        .any((d) => d.subscriptionId == subId && !d.isExtraOrder);
  }

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

  // ── Build delivery ─────────────────────────────────────────────────────

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

  String _subscriptionsCol(String vid) =>
      '${AppConstants.colVendors}/$vid/${AppConstants.colSubscriptions}';

  void _markGeneratedToday(String vendorId) {
    LocalStorageService.saveSetting(
        _lastGenKey(vendorId), _dateKey(DateTime.now()));
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      final end = (i + size > list.length) ? list.length : i + size;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  @override
  void onClose() {
    _midnightTimer?.cancel();
    super.onClose();
  }
}