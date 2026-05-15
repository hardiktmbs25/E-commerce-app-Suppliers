// lib/data/models/sync_action_model.dart
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
part 'sync_action_model.g.dart';
enum SyncActionType {
  createCustomer,
  updateCustomer,
  deleteCustomer,
  markDelivery,
  createInvoice,
  recordPayment,
  updateSubscription,
  placeExtraOrder,
}

/// Represents a write operation queued while the device was offline.
/// The SyncService processes these in FIFO order when connectivity resumes.
@HiveType(typeId: AppConstants.tidSyncAction)
class SyncActionModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String actionTypeStr;
  @HiveField(2) final String collection;       // Firestore collection
  @HiveField(3) final String? documentId;      // null for creates
  @HiveField(4) final Map<String, dynamic> payload;
  @HiveField(5) final DateTime createdAt;
  @HiveField(6) int retryCount;
  @HiveField(7) bool isFailed;                 // gave up after maxRetries
  @HiveField(8) final String? localId;         // local Hive key for optimistic update

  SyncActionModel({
    required this.id,
    required this.actionTypeStr,
    required this.collection,
    this.documentId,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.isFailed = false,
    this.localId,
  });

  SyncActionType get actionType => SyncActionType.values.firstWhere(
          (e) => e.name == actionTypeStr);
}