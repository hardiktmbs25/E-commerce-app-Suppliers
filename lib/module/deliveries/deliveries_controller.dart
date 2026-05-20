// lib/modules/deliveries/deliveries_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/delivery_model.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../routes/app_routes.dart';
import '../../services/local_storage_service.dart';
import '../../core/utils/logger.dart';
import '../../services/delivery_scheduler_service.dart';

class DeliveriesController extends GetxController {
  final DeliveryRepository _repo = Get.find<DeliveryRepository>();
  // Use a getter so the find happens at call time, not at construction time.
  // This prevents crashes if the service is registered after the controller.
  DeliverySchedulerService get _scheduler {
    if (!Get.isRegistered<DeliverySchedulerService>()) {
      Get.put<DeliverySchedulerService>(DeliverySchedulerService(), permanent: true);
    }
    return Get.find<DeliverySchedulerService>();
  }

  final RxList<DeliveryModel> allDeliveries      = <DeliveryModel>[].obs;
  final RxList<DeliveryModel> filteredDeliveries = <DeliveryModel>[].obs;
  final RxString statusFilter  = 'all'.obs;
  final RxString searchQuery   = ''.obs;
  final RxBool   isLoading     = true.obs;
  final RxString markingId     = ''.obs;

  final searchCtrl = TextEditingController();

  String? get vendorId => LocalStorageService.getVendor()?.id;
  StreamSubscription? _sub;

  // ── Safety timer: never leave spinner on indefinitely ─────────────────
  Timer? _loadingTimeout;

  int get deliveredCount => allDeliveries.where((d) => d.isDelivered).length;
  int get pendingCount   => allDeliveries.where((d) => d.isPending).length;
  int get missedCount    => allDeliveries.where((d) => d.isMissed).length;
  double get totalAmount => allDeliveries.fold(0.0, (total, d) => total + d.amount);

  @override
  void onInit() {
    super.onInit();
    ever(statusFilter, (_) => _applyFilter());
    ever(searchQuery,  (_) => _applyFilter());

    // Step 1: Load from local cache immediately so screen is never blank
    final cached = LocalStorageService.getTodayDeliveries();
    if (cached.isNotEmpty) {
      allDeliveries.assignAll(cached);
      _applyFilter();
      // Show cached data right away, stream will refresh it
      isLoading.value = false;
    }

    // Step 2: Safety timeout — stop spinner after 8s no matter what
    _loadingTimeout = Timer(const Duration(seconds: 8), () {
      if (isLoading.value) {
        isLoading.value = false;
        AppLogger.w('Deliveries stream timed out, showing cached/empty state');
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Run daily schedule generation (skips if already done today)
    if (vendorId != null) _scheduler.runIfNeeded(vendorId!);
    _initStream();
  }

  void _initStream() {
    // If no vendor, stop loading and show empty
    if (vendorId == null) {
      isLoading.value = false;
      return;
    }

    _sub = _repo.watchTodayDeliveries(vendorId!).listen(
          (list) {
        _loadingTimeout?.cancel();
        allDeliveries.assignAll(list);
        _applyFilter();
        isLoading.value = false;
      },
      onError: (e) {
        _loadingTimeout?.cancel();
        AppLogger.e('Deliveries stream error', e);
        // Fall back to local cache on stream error
        final cached = LocalStorageService.getTodayDeliveries();
        allDeliveries.assignAll(cached);
        _applyFilter();
        isLoading.value = false;
        Get.snackbar(
          'Offline Mode',
          'Showing cached deliveries. Check your connection.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
        );
      },
      cancelOnError: false, // keep stream alive even after one error
    );
  }

  /// Pull-to-refresh: re-fetch from local cache + restart stream
  Future<void> refresh() async {
    final cached = LocalStorageService.getTodayDeliveries();
    allDeliveries.assignAll(cached);
    _applyFilter();
    // runIfNeeded: only generates if not already done today.
    // This prevents duplicate deliveries on every pull-to-refresh.
    // Each subscription gets exactly ONE delivery per its schedule period.
    if (vendorId != null) await _scheduler.runIfNeeded(vendorId!);
    // Cancel old stream and restart to get fresh Firestore data
    await _sub?.cancel();
    _initStream();
  }

  void _applyFilter() {
    var list = allDeliveries.toList();

    if (statusFilter.value != 'all') {
      list = list.where((d) => d.statusStr == statusFilter.value).toList();
    }

    final q = searchQuery.value.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((d) =>
      d.customerName.toLowerCase().contains(q) ||
          d.customerAddress.toLowerCase().contains(q)).toList();
    }

    filteredDeliveries.assignAll(list);
  }

  void onSearchChanged(String value) => searchQuery.value = value;

  void clearSearch() {
    searchCtrl.clear();
    searchQuery.value = '';
  }

  Future<void> markDelivery(DeliveryModel delivery, DeliveryStatus status,
      {String? notes}) async {
    if (vendorId == null) return;
    markingId.value = delivery.id;
    final result = await _repo.updateDeliveryStatus(
        vendorId!, delivery, status, notes: notes);
    result.fold(
          (f) => Get.snackbar('Error', f.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          colorText: Colors.white),
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

  void showMarkWithNotesDialog(DeliveryModel delivery, DeliveryStatus status) {
    final notesCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          status == DeliveryStatus.missed ? 'Reason for Missing' : 'Add Notes',
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
              fontSize: 16),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Customer: ${delivery.customerName}',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: notesCtrl,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
              hintText: status == DeliveryStatus.missed
                  ? 'e.g., Customer not home...'
                  : 'Any delivery notes...',
              hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary)),
            ),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status == DeliveryStatus.missed
                  ? AppColors.error : AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              markDelivery(delivery, status,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim());
            },
            child: Text(status == DeliveryStatus.missed ? 'Mark Missed' : 'Confirm',
                style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> markAllDelivered() async {
    if (vendorId == null) return;
    final pending = allDeliveries.where((d) => d.isPending).toList();
    if (pending.isEmpty) return;

    final confirmed = await Get.dialog<bool>(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Mark All Delivered?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
      content: Text('This will mark ${pending.length} pending deliveries as delivered.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Get.back(result: false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins'))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () => Get.back(result: true),
          child: const Text('Confirm', style: TextStyle(color: Colors.white,
              fontFamily: 'Poppins')),
        ),
      ],
    ));

    if (confirmed != true) return;
    for (final d in pending) {
      await _repo.updateDeliveryStatus(vendorId!, d, DeliveryStatus.delivered);
    }
    Get.snackbar('✅ All Marked', '${pending.length} deliveries marked delivered.',
        snackPosition: SnackPosition.TOP);
  }

  void goToAddDelivery() => Get.toNamed(Routes.addDelivery);
  void goToExtraOrder()  => Get.toNamed(Routes.extraOrder);
  void goToHistory()     => Get.toNamed(Routes.deliveryHistory);
  void goToDetail(DeliveryModel delivery) =>
      Get.toNamed(Routes.deliveryDetail, arguments: delivery);

  @override
  void onClose() {
    _loadingTimeout?.cancel();
    _sub?.cancel();
    searchCtrl.dispose();
    super.onClose();
  }
}