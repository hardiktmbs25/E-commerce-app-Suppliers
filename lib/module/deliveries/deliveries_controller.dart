// lib/modules/deliveries/deliveries_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import '../../data/models/delivery_model.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../services/local_storage_service.dart';
import '../../core/utils/logger.dart';

class DeliveriesController extends GetxController {
  final DeliveryRepository _repo = Get.find<DeliveryRepository>();

  final RxList<DeliveryModel> allDeliveries      = <DeliveryModel>[].obs;
  final RxList<DeliveryModel> filteredDeliveries = <DeliveryModel>[].obs;
  final RxString statusFilter  = 'all'.obs;
  final RxBool   isLoading     = true.obs;
  final RxString markingId     = ''.obs; // ID being processed

  String? get vendorId => LocalStorageService.getVendor()?.id;
  StreamSubscription? _sub;

  // Computed
  int get deliveredCount => allDeliveries.where((d) => d.isDelivered).length;
  int get pendingCount   => allDeliveries.where((d) => d.isPending).length;
  int get missedCount    => allDeliveries.where((d) => d.isMissed).length;
  double get totalAmount => allDeliveries.fold(0.0, (total, d) => total + d.amount);

  @override
  void onInit() {
    super.onInit();
    // Cache first
    allDeliveries.assignAll(LocalStorageService.getTodayDeliveries());
    _applyFilter();
    ever(statusFilter, (_) => _applyFilter());
  }

  @override
  void onReady() {
    super.onReady();
    _initStream();
  }

  void _initStream() {
    if (vendorId == null) return;
    _sub = _repo.watchTodayDeliveries(vendorId!).listen(
          (list) {
        allDeliveries.assignAll(list);
        _applyFilter();
        isLoading.value = false;
      },
      onError: (e) {
        AppLogger.e('Deliveries stream error', e);
        isLoading.value = false;
      },
    );
  }

  void _applyFilter() {
    if (statusFilter.value == 'all') {
      filteredDeliveries.assignAll(allDeliveries);
    } else {
      filteredDeliveries.assignAll(
          allDeliveries.where((d) => d.statusStr == statusFilter.value).toList());
    }
  }

  Future<void> markDelivery(DeliveryModel delivery, DeliveryStatus status,
      {String? notes}) async {
    if (vendorId == null) return;
    markingId.value = delivery.id;

    final result = await _repo.updateDeliveryStatus(
        vendorId!, delivery, status, notes: notes);

    result.fold(
          (f) => Get.snackbar('Error', f.message,
          snackPosition: SnackPosition.TOP),
          (_) {
        final label = status == DeliveryStatus.delivered ? '✅ Delivered' :
        status == DeliveryStatus.missed    ? '❌ Missed' : 'Updated';
        Get.snackbar(label, '${delivery.customerName} updated.',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 2));
      },
    );
    markingId.value = '';
  }

  Future<void> markAllDelivered() async {
    if (vendorId == null) return;
    final pending = allDeliveries.where((d) => d.isPending).toList();
    for (final d in pending) {
      await _repo.updateDeliveryStatus(vendorId!, d, DeliveryStatus.delivered);
    }
    Get.snackbar('✅ All Marked', '${pending.length} deliveries marked delivered.',
        snackPosition: SnackPosition.TOP);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}