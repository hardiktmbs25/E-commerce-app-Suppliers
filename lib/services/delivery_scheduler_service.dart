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
  Timer? _slotWatcherTimer;
  int _tickCount = 0;

  static String _lastGenKey(String vid) => 'scheduler_last_gen_$vid';

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────

  @override
  void onReady() {
    super.onReady();

    // 1. Run daily generation for today/tomorrow if needed
    final vendorId = LocalStorageService.vendorId;
    if (vendorId != null) {
      runIfNeeded(vendorId);
    }

    // 2. Schedule midnight generation runs
    _scheduleMidnightRun();

    // 3. Start background slots watcher (15 mins interval)
    _startSlotWatcher();
  }

  @override
  void onClose() {
    _midnightTimer?.cancel();
    _slotWatcherTimer?.cancel();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────
  // MIDNIGHT GENERATION
  // ─────────────────────────────────────────────────────────────

  void _scheduleMidnightRun() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);

    AppLogger.i('Scheduler: next midnight run scheduled in ${diff.inMinutes} minutes');

    _midnightTimer = Timer(diff, () async {
      final vendorId = LocalStorageService.vendorId;
      if (vendorId != null) {
        AppLogger.i('Scheduler: Midnight reached, generating deliveries...');
        await Get.find<DeliveryGenerationService>().generateTodayAndTomorrow(vendorId);
        _markGeneratedToday(vendorId);
      }
      _scheduleMidnightRun(); // reschedule for next day
    });
  }

  // ─────────────────────────────────────────────────────────────
  // SLOT WATCHER & SYNC (Every 15 Minutes)
  // ─────────────────────────────────────────────────────────────

  void _startSlotWatcher() {
    _slotWatcherTimer?.cancel();
    _tickCount = 0;

    _slotWatcherTimer = Timer.periodic(
      const Duration(minutes: 15),
          (_) async {
        final vendorId = LocalStorageService.vendorId;
        if (vendorId == null) return;

        AppLogger.i('Scheduler: Running 15-minute slot checks...');

        // 1. Every 15 minutes: Auto-missed rule transition
        await _markExpiredPendingAsMissed(vendorId);

        _tickCount++;

        // 2. Every 30 minutes (2 ticks): Sync offline queue
        if (_tickCount % 2 == 0) {
          AppLogger.i('Scheduler: Running 30-minute offline sync queue...');
          await Get.find<SyncService>().syncPendingActions();
        }

        // 3. Every 60 minutes (4 ticks): Check overdue invoices
        if (_tickCount % 4 == 0) {
          AppLogger.i('Scheduler: Checking overdue invoices...');
          try {
            await Get.find<BillingService>().markOverdueBills(vendorId);
          } catch (e) {
            AppLogger.w('Scheduler: markOverdueBills unavailable', e);
          }
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────

  /// Runs today's and tomorrow's generation if it hasn't been performed today yet.
  Future<void> runIfNeeded(String vendorId) async {
    final today = _dateKey(DateTime.now());
    final lastGen = LocalStorageService.getSetting<String>(_lastGenKey(vendorId));

    if (lastGen == today) {
      AppLogger.i('Scheduler: Deliveries for today already generated.');
      return;
    }

    isGenerating.value = true;
    try {
      AppLogger.i('Scheduler: Initializing daily generation for today & tomorrow...');
      await Get.find<DeliveryGenerationService>().generateTodayAndTomorrow(vendorId);
      _markGeneratedToday(vendorId);
    } catch (e) {
      AppLogger.e('Scheduler: runIfNeeded generation failed', e);
    } finally {
      isGenerating.value = false;
    }
  }

  /// Triggers a generation refresh when a new subscription is added.
  /// Duplicate protection will ensure that only the new deliveries are created.
  Future<void> generateForNewSubscription(
      String vendorId,
      SubscriptionModel sub,
      String customerAddress,
      ) async {
    AppLogger.i('Scheduler: New subscription added, refreshing deliveries...');
    await Get.find<DeliveryGenerationService>().generateTodayAndTomorrow(vendorId);
  }

  // ─────────────────────────────────────────────────────────────
  // AUTO-MISSED RULE LOGIC (slot + 2 hours)
  // ─────────────────────────────────────────────────────────────

  Future<void> _markExpiredPendingAsMissed(String vendorId) async {
    final now = DateTime.now();
    final todayDeliveries = LocalStorageService.getTodayDeliveries();
    final deliveryRepo = Get.find<DeliveryRepository>();

    for (final delivery in todayDeliveries) {
      if (delivery.status != DeliveryStatus.pending) {
        continue;
      }

      final slotTime = _slotToDateTime(delivery.deliverySlot);
      final missedTime = slotTime.add(const Duration(hours: 2));

      // If the slot has elapsed by more than 2 hours, transition to missed
      if (now.isAfter(missedTime)) {
        AppLogger.i('Scheduler: Delivery ${delivery.id} for ${delivery.customerName} has elapsed. Marking missed.');
        await deliveryRepo.updateDeliveryStatus(vendorId, delivery, DeliveryStatus.missed);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  DateTime _slotToDateTime(String slot) {
    final now = DateTime.now();
    final cleaned = slot.trim().toUpperCase();
    final parts = cleaned.split(' ');

    if (parts.length != 2) {
      return DateTime(now.year, now.month, now.day, 7, 0);
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

    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  void _markGeneratedToday(String vendorId) {
    LocalStorageService.saveSetting(_lastGenKey(vendorId), _dateKey(DateTime.now()));
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}