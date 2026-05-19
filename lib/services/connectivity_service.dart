// lib/services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../data/models/sync_action_model.dart';
import 'local_storage_service.dart';

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

// ── SyncService ───────────────────────────────────────────────────────────────
/// Drains the offline SyncAction queue by replaying writes to Firestore.
///
/// SYNC FLOW:
/// 1. ConnectivityService detects network restored → calls syncPendingActions()
/// 2. SyncService reads all queued SyncActionModels from Hive in FIFO order
/// 3. For each action, it replays the Firestore write (create/update/delete)
/// 4. On success: removes the action from the queue
/// 5. On failure: increments retryCount; after maxRetries marks as failed
///    (failed actions are shown in a UI banner for manual review)
///
/// CONFLICT RESOLUTION:
/// Last-write-wins using Firestore's server timestamp. Since this app has
/// a single vendor per account, conflicts from multiple devices are rare
/// but handled by Firestore's atomic server timestamps.
class SyncService extends GetxService {
  final RxInt pendingCount = 0.obs;
  final RxBool isSyncing   = false.obs;

  @override
  void onInit() {
    super.onInit();
    _updatePendingCount();
  }

  void _updatePendingCount() {
    pendingCount.value = LocalStorageService.pendingSyncCount;
  }

  Future<void> syncPendingActions() async {
    if (isSyncing.value) return;
    final actions = LocalStorageService.getSyncQueue();
    if (actions.isEmpty) return;

    isSyncing.value = true;
    AppLogger.i('SyncService: syncing ${actions.length} actions');

    for (final action in actions) {
      try {
        await _executeAction(action);
        await LocalStorageService.removeSyncAction(action.id);
        AppLogger.i('SyncService: completed ${action.actionTypeStr}');
      } catch (e) {
        action.retryCount++;
        if (action.retryCount >= AppConstants.maxSyncRetries) {
          await LocalStorageService.markSyncActionFailed(action.id);
          AppLogger.e('SyncService: action permanently failed', e);
        } else {
          await action.save();
          AppLogger.w('SyncService: action retry ${action.retryCount}', e);
        }
      }
    }

    isSyncing.value = false;
    _updatePendingCount();
  }

  Future<void> _executeAction(SyncActionModel action) async {
    final db = FirebaseFirestore.instance;
    final ref = action.documentId != null
        ? db.collection(action.collection).doc(action.documentId)
        : db.collection(action.collection).doc();

    switch (action.actionType) {
      case SyncActionType.createCustomer:
      case SyncActionType.createInvoice:
      case SyncActionType.placeExtraOrder:
        await ref.set(action.payload);
        break;

      case SyncActionType.updateCustomer:
      case SyncActionType.markDelivery:
      case SyncActionType.recordPayment:
      case SyncActionType.updateSubscription:
        final payload = Map<String, dynamic>.from(action.payload);
        payload['updatedAt'] = FieldValue.serverTimestamp();
        await ref.update(payload);
        break;

      case SyncActionType.deleteCustomer:
        await ref.delete();
        break;
    }
  }
}

// Import pulled in here so SyncService can reference it
