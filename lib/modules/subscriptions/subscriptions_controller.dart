// lib/modules/subscriptions/subscriptions_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import '../../data/models/subscription_model.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../services/auth_service.dart';
import '../../services/local_storage_service.dart';
import '../../core/utils/logger.dart';

class SubscriptionsController extends GetxController {
  final SubscriptionRepository _repo = Get.find<SubscriptionRepository>();

  final RxList<SubscriptionModel> allSubs      = <SubscriptionModel>[].obs;
  final RxList<SubscriptionModel> filteredSubs = <SubscriptionModel>[].obs;
  final RxMap<String, List<SubscriptionModel>> groupedSubs = <String, List<SubscriptionModel>>{}.obs;
  final RxString statusFilter = 'all'.obs;
  final RxString searchQuery  = ''.obs;
  final RxBool   isLoading    = true.obs;

  String? get vendorId => AuthService.to.uid;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    final cached = LocalStorageService.getSubscriptions();
    allSubs.assignAll(cached);
    if (cached.isNotEmpty) {
      isLoading.value = false;
    }
    _applyFilter();
    debounce(searchQuery, (_) => _applyFilter(), time: const Duration(milliseconds: 300));
    ever(statusFilter, (_) => _applyFilter());
  }


  @override
  void onReady() {
    super.onReady();
    _initStream();
  }

  void _initStream() {
    final uid = vendorId;
    if (uid == null) {
      isLoading.value = false;
      return;
    }
    
    _sub = _repo.watchSubscriptions(uid).listen(
      (subs) {
        allSubs.assignAll(subs);
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
    
    // Group by Customer ID
    final Map<String, List<SubscriptionModel>> groups = {};
    for (var sub in result) {
      if (!groups.containsKey(sub.customerId)) {
        groups[sub.customerId] = [];
      }
      groups[sub.customerId]!.add(sub);
    }
    groupedSubs.assignAll(groups);
  }

  Future<void> togglePause(SubscriptionModel sub) async {
    if (vendorId == null) return;
    
    if (sub.isActive) {
      await _repo.pauseSubscription(vendorId!, sub.id, null);
    } else {
      await _repo.resumeSubscription(vendorId!, sub.id);
    }
    
    Get.snackbar(
      sub.isActive ? '⏸ Paused' : '▶ Resumed',
      '${sub.customerName}\'s subscription ${sub.isActive ? 'paused' : 'resumed'}.',
      snackPosition: SnackPosition.TOP,
    );
  }

  Future<void> cancelSubscription(SubscriptionModel sub) async {
    if (vendorId == null) return;
    await _repo.cancelSubscription(vendorId!, sub.id);
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
