// lib/services/sync_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../data/models/sync_action_model.dart';
import 'local_storage_service.dart';

/// Drains the offline SyncAction queue by replaying writes to Firestore.
///
/// SYNC FLOW:
/// 1. ConnectivityService detects network restored → calls syncPendingActions()
/// 2. SyncService reads all queued SyncActionModels from Hive in FIFO order
/// 3. For each action, it replays the Firestore write (create/update/delete)
/// 4. On success: removes the action from the queue
/// 5. On failure: increments retryCount; after maxRetries marks as failed
///    (failed actions are shown in a UI banner for manual review)
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
    if (actions.isEmpty) {
      _updatePendingCount();
      return;
    }

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
      case SyncActionType.createSubscription:
      case SyncActionType.createBill:
      case SyncActionType.recordBillPayment:
      case SyncActionType.createLedgerEntry:
      case SyncActionType.recordExpense:
      case SyncActionType.createRoute:
      case SyncActionType.addStaff:
        await ref.set(action.payload);
        break;

      case SyncActionType.updateCustomer:
      case SyncActionType.markDelivery:
      case SyncActionType.recordPayment:
      case SyncActionType.updateSubscription:
      case SyncActionType.updateBill:
      case SyncActionType.updateStock:
      case SyncActionType.updateWallet:
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
