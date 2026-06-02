// lib/services/delivery_scheduler_service.dart
import 'package:get/get.dart';
import '../core/utils/logger.dart';
import '../data/models/delivery_model.dart';
import '../data/repositories/delivery_repository.dart';
import 'local_storage_service.dart';
import 'delivery_generation_service.dart';

/// Manual-only scheduler.
///
/// No background timers. No auto-generation.
/// The vendor explicitly picks a time slot on the Deliveries screen and taps
/// "Generate" — this service creates the deliveries for that slot.
/// Missed-marking is done on demand (called when vendor opens the screen or
/// taps "Mark Missed").
class DeliverySchedulerService extends GetxService {

  final RxBool isGenerating = false.obs;

  // ─────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────

  /// Generate deliveries for [selectedSlots] (list of startTime strings like
  /// "07:00 AM") for today's date.
  /// Returns the total number of new deliveries created.
  Future<int> generateForSlots(
      String vendorId,
      List<String> selectedSlots,
      ) async {
    if (selectedSlots.isEmpty) return 0;

    isGenerating.value = true;
    int total = 0;
    try {
      final now = DateTime.now();
      for (final slotStartTime in selectedSlots) {
        AppLogger.i('Scheduler: Generating for slot $slotStartTime');
        total += await Get.find<DeliveryGenerationService>()
            .generateForDateAndSlot(vendorId, now, slotStartTime);
      }
      AppLogger.i('Scheduler: Generated $total deliveries across ${selectedSlots.length} slot(s)');
    } catch (e) {
      AppLogger.e('Scheduler: generateForSlots failed', e);
    } finally {
      isGenerating.value = false;
    }
    return total;
  }

  /// Mark pending deliveries as missed once their slot window has closed.
  /// Call this when the vendor opens the screen or taps "Mark Missed".
  Future<void> markExpiredAsMissed(String vendorId) async {
    final now          = DateTime.now();
    final deliveries   = LocalStorageService.getTodayDeliveries();
    final timeSlots    = LocalStorageService.getTimeSlots();
    final deliveryRepo = Get.find<DeliveryRepository>();

    for (final delivery in deliveries) {
      if (delivery.status != DeliveryStatus.pending) continue;

      final slotModel = timeSlots
          .firstWhereOrNull((s) => s.startTime == delivery.deliverySlot);

      final missedAfter = slotModel != null
          ? slotModel.getEndDateTime(delivery.scheduledDate)
          : delivery.scheduledDate.add(const Duration(hours: 2));

      if (now.isAfter(missedAfter)) {
        AppLogger.i(
          'Scheduler: Marking missed — ${delivery.customerName} '
              '(slot ${delivery.deliverySlot})',
        );
        await deliveryRepo.updateDeliveryStatus(
            vendorId, delivery, DeliveryStatus.missed);
      }
    }
  }
}