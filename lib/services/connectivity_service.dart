// lib/services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../data/models/sync_action_model.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';

/// Monitors device connectivity and exposes a reactive [isOnline] flag.
///
/// WHY IT EXISTS:
/// Controllers and repositories check [isOnline] before deciding whether
/// to write directly to Firestore or queue a SyncAction locally.
/// When [isOnline] flips from false → true, it triggers the SyncService
/// to drain any queued offline actions.
class ConnectivityService extends GetxService {
  final RxBool isOnline = true.obs;
  late StreamSubscription<List<ConnectivityResult>> _sub;

  @override
  void onInit() {
    super.onInit();

    // Initial state
    Connectivity().checkConnectivity().then(_updateStatus);

    // Listen for changes
    _sub = Connectivity()
        .onConnectivityChanged
        .listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final wasOnline = isOnline.value;

    // Device is offline only if NONE exists
    isOnline.value = !results.contains(ConnectivityResult.none);

    if (!wasOnline && isOnline.value) {
      AppLogger.i('Back online — triggering sync');

      try {
        Get.find<SyncService>().syncPendingActions();
      } catch (_) {
        // SyncService not registered yet
      }
    }
  }

  @override
  void onClose() {
    _sub.cancel();
    super.onClose();
  }
}

