// lib/services/delivery_scheduler_service.dart
import 'dart:async';
import 'package:get/get.dart';
import '../core/utils/logger.dart';
import '../data/models/delivery_model.dart';
import '../data/models/subscription_model.dart';
import '../data/repositories/delivery_repository.dart';
import 'billing_service.dart';
import 'local_storage_service.dart';
import 'delivery_generation_service.dart';
import 'sync_service.dart';

class DeliverySchedulerService extends GetxService {
  final RxBool isGenerating = false.obs;

  Timer? _midnightTimer;
  Timer? _engineTimer;
  int _tickCount = 0;

  // Tracks which (date + slotStartTime) pairs have already been generated
  // this app session, so the engine doesn't re-trigger within the same window.
  // Key format: "yyyy-M-d_slotStartTime"  e.g. "2026-5-29_03:00 PM"
  final Set<String> _generatedSlotKeys = {};

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────

  @override
  void onReady() {
    super.onReady();

    final vendorId = LocalStorageService.vendorId;
    if (vendorId != null) {
      // On startup: catch up any slots that already opened today
      _catchUpPastSlotsForToday(vendorId);
    }

    // Schedule the midnight job that pre-generates tomorrow
    _scheduleMidnightRun();

    // Start 5-minute engine that fires deliveries at slot-start time
    _startEngine();
  }

  @override
  void onClose() {
    _midnightTimer?.cancel();
    _engineTimer?.cancel();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────
  // STARTUP CATCH-UP
  // ─────────────────────────────────────────────────────────────

  /// On app open, generate deliveries for any slots that have already started
  /// today but whose deliveries don't exist in cache yet (e.g. app was closed
  /// during an earlier slot window).
  Future<void> _catchUpPastSlotsForToday(String vendorId) async {
    AppLogger.i('Scheduler: Startup catch-up for past/open slots today...');
    final now       = DateTime.now();
    final timeSlots = LocalStorageService.getTimeSlots();

    for (final slot in timeSlots) {
      if (!slot.isActive) continue;
      final startTime = slot.getStartDateTime(now);

      // If the slot has already opened (or is open right now), generate
      if (now.isAfter(startTime) || now.isAtSameMomentAs(startTime)) {
        AppLogger.i('Scheduler: Catch-up → slot ${slot.label}');
        await Get.find<DeliveryGenerationService>()
            .generateForDateAndSlot(vendorId, now, slot.startTime);
        _markSlotGenerated(now, slot.startTime);
      }
    }

    // After catch-up, mark any past-window deliveries as missed
    await _markExpiredPendingAsMissed(vendorId);
  }

  // ─────────────────────────────────────────────────────────────
  // MIDNIGHT JOB — pre-generates tomorrow's deliveries
  // ─────────────────────────────────────────────────────────────

  void _scheduleMidnightRun() {
    _midnightTimer?.cancel();

    final now      = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff     = midnight.difference(now);

    AppLogger.i('Scheduler: Midnight run in ${diff.inMinutes} min');

    _midnightTimer = Timer(diff, () async {
      final vendorId = LocalStorageService.vendorId;
      if (vendorId != null) {
        AppLogger.i('Scheduler: Midnight — pre-generating tomorrow\'s deliveries');
        // forceAll: false for today (engine handles remaining slots),
        // forceAll: true for tomorrow (pre-generate the whole day)
        await Get.find<DeliveryGenerationService>()
            .generateTodayAndTomorrow(vendorId);

        // Reset session tracking for the new day
        _generatedSlotKeys.clear();
      }
      _scheduleMidnightRun(); // reschedule for next midnight
    });
  }

  // ─────────────────────────────────────────────────────────────
  // ENGINE — fires every 5 minutes
  // ─────────────────────────────────────────────────────────────

  void _startEngine() {
    _engineTimer?.cancel();
    _tickCount = 0;

    _engineTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      final vendorId = LocalStorageService.vendorId;
      if (vendorId == null) return;

      AppLogger.i('Scheduler Engine: Tick ${_tickCount + 1}');

      // 1. Fire deliveries for slots whose window just opened
      await _checkAndGenerateStartingSlots(vendorId);

      // 2. Mark deliveries missed once their slot window closes
      await _markExpiredPendingAsMissed(vendorId);

      _tickCount++;

      // 3. Sync offline queue every 30 min
      if (_tickCount % 6 == 0) {
        await Get.find<SyncService>().syncPendingActions();
      }

      // 4. Check overdue invoices every 60 min
      if (_tickCount % 12 == 0) {
        try {
          await Get.find<BillingService>().markOverdueBills(vendorId);
        } catch (e) {
          AppLogger.w('Scheduler: markOverdueBills failed', e);
        }
      }
    });
  }

  /// Checks every active time slot. If `now` falls within the 6-minute trigger
  /// window after slot start, generates deliveries for that slot — once per day.
  Future<void> _checkAndGenerateStartingSlots(String vendorId) async {
    final now       = DateTime.now();
    final timeSlots = LocalStorageService.getTimeSlots();

    for (final slot in timeSlots) {
      if (!slot.isActive) continue;

      final startTime = slot.getStartDateTime(now);
      final diff      = now.difference(startTime).inMinutes;

      // 6-minute window covers the worst-case gap between engine ticks
      if (diff >= 0 && diff < 6) {
        final key = _slotKey(now, slot.startTime);
        if (_generatedSlotKeys.contains(key)) continue; // already fired today

        AppLogger.i('Scheduler: Slot ${slot.label} opened — generating deliveries');
        await Get.find<DeliveryGenerationService>()
            .generateForDateAndSlot(vendorId, now, slot.startTime);
        _markSlotGenerated(now, slot.startTime);
      }
    }
  }

  Future<void> _markExpiredPendingAsMissed(String vendorId) async {
    final now             = DateTime.now();
    final todayDeliveries = LocalStorageService.getTodayDeliveries();
    final deliveryRepo    = Get.find<DeliveryRepository>();
    final timeSlots       = LocalStorageService.getTimeSlots();

    for (final delivery in todayDeliveries) {
      if (delivery.status != DeliveryStatus.pending) continue;

      final slotModel = timeSlots
          .firstWhereOrNull((s) => s.startTime == delivery.deliverySlot);

      final missedTime = slotModel != null
          ? slotModel.getEndDateTime(delivery.scheduledDate)
          : delivery.scheduledDate.add(const Duration(hours: 2));

      if (now.isAfter(missedTime)) {
        AppLogger.i(
          'Scheduler: ${delivery.customerName} slot closed at '
              '${missedTime.toIso8601String()} → MISSED',
        );
        await deliveryRepo.updateDeliveryStatus(
            vendorId, delivery, DeliveryStatus.missed);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────

  /// Called on screen open to catch up any slots that opened since last tick.
  /// Safe to call repeatedly — generation is idempotent via deterministic IDs.
  Future<void> runIfNeeded(String vendorId) async {
    isGenerating.value = true;
    try {
      await _catchUpPastSlotsForToday(vendorId);
    } catch (e) {
      AppLogger.e('Scheduler: runIfNeeded failed', e);
    } finally {
      isGenerating.value = false;
    }
  }

  /// Called after a new subscription is created.
  /// Only generates for slots whose window is currently open right now.
  Future<void> generateForNewSubscription(
      String vendorId,
      SubscriptionModel sub,
      String customerAddress,
      ) async {
    final now       = DateTime.now();
    final timeSlots = LocalStorageService.getTimeSlots();

    for (final slot in timeSlots) {
      if (!slot.isActive) continue;
      final start = slot.getStartDateTime(now);
      final end   = slot.getEndDateTime(now);

      if (now.isAfter(start) && now.isBefore(end)) {
        AppLogger.i('Scheduler: New subscription — open slot ${slot.label}');
        await Get.find<DeliveryGenerationService>()
            .generateForDateAndSlot(vendorId, now, slot.startTime);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  String _slotKey(DateTime date, String startTime) =>
      '${date.year}-${date.month}-${date.day}_$startTime';

  void _markSlotGenerated(DateTime date, String startTime) =>
      _generatedSlotKeys.add(_slotKey(date, startTime));
}