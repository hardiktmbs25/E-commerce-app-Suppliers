// lib/modules/subscriptions/subscriptions_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/models/subscription_model.dart';
import '../../services/local_storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

class SubscriptionsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<SubscriptionModel> allSubs      = <SubscriptionModel>[].obs;
  final RxList<SubscriptionModel> filteredSubs = <SubscriptionModel>[].obs;
  final RxString statusFilter = 'all'.obs;
  final RxString searchQuery  = ''.obs;
  final RxBool   isLoading    = true.obs;

  String? get vendorId => LocalStorageService.getVendor()?.id;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    allSubs.assignAll(LocalStorageService.getSubscriptions());
    filteredSubs.assignAll(allSubs);
    debounce(searchQuery, (_) => _applyFilter(),
        time: const Duration(milliseconds: 300));
    ever(statusFilter, (_) => _applyFilter());
  }

  @override
  void onReady() {
    super.onReady();
    _initStream();
  }

  void _initStream() {
    if (vendorId == null) return;
    final col = '${AppConstants.colVendors}/$vendorId/${AppConstants.colSubscriptions}';
    _sub = _db.collection(col).snapshots().listen(
          (snap) {
        final subs = snap.docs.map((d) => SubscriptionModel.fromFirestore(d)).toList();
        allSubs.assignAll(subs);
        LocalStorageService.saveSubscriptions(subs);
        _applyFilter();
        isLoading.value = false;
      },
      onError: (e) {
        AppLogger.e('Subscriptions stream error', e);
        isLoading.value = false;
      },
    );
  }

  void _applyFilter() {
    var result = allSubs.toList();
    if (statusFilter.value != 'all') {
      result = result.where((s) => s.statusStr == statusFilter.value).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result.where((s) =>
      s.customerName.toLowerCase().contains(q) ||
          s.serviceTypeStr.toLowerCase().contains(q)).toList();
    }
    filteredSubs.assignAll(result);
  }

  Future<void> togglePause(SubscriptionModel sub) async {
    if (vendorId == null) return;
    final col = '${AppConstants.colVendors}/$vendorId/${AppConstants.colSubscriptions}';
    final newStatus = sub.isActive
        ? SubscriptionStatus.paused.name
        : SubscriptionStatus.active.name;
    await _db.collection(col).doc(sub.id).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    Get.snackbar(
      sub.isActive ? '⏸ Paused' : '▶ Resumed',
      '${sub.customerName}\'s subscription ${sub.isActive ? 'paused' : 'resumed'}.',
      snackPosition: SnackPosition.TOP,
    );
  }

  Future<void> cancelSubscription(SubscriptionModel sub) async {
    if (vendorId == null) return;
    final col = '${AppConstants.colVendors}/$vendorId/${AppConstants.colSubscriptions}';
    await _db.collection(col).doc(sub.id).update({
      'status': SubscriptionStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Computed
  int get activeCount   => allSubs.where((s) => s.isActive).length;
  int get pausedCount   => allSubs.where((s) => s.isPaused).length;
  double get totalMonthlyRevenue =>
      allSubs.where((s) => s.isActive)
          .fold(0.0, (total, s) => total + s.estimatedMonthlyRevenue);

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}