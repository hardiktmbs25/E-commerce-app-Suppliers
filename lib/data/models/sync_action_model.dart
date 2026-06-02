// lib/data/models/sync_action_model.dart
// MODIFIED: added billing sync action types.
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
part 'sync_action_model.g.dart';

enum SyncActionType {
  // existing
  createCustomer,
  updateCustomer,
  deleteCustomer,
  markDelivery,
  createInvoice,
  recordPayment,
  updateSubscription,
  placeExtraOrder,
  createSubscription,
  // NEW billing types ↓
  createBill,
  updateBill,
  recordBillPayment,
  createLedgerEntry,
  recordExpense,
  updateStock,
  createRoute,
  addStaff,
  updateWallet,
}

@HiveType(typeId: AppConstants.tidSyncAction)
class SyncActionModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String actionTypeStr;
  @HiveField(2) final String collection;
  @HiveField(3) final String? documentId;
  @HiveField(4, defaultValue: {}) final Map<String, dynamic> payload;
  @HiveField(5) final DateTime createdAt;
  @HiveField(6, defaultValue: 0) int retryCount;
  @HiveField(7, defaultValue: false) bool isFailed;
  @HiveField(8) final String? localId;

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
          (e) => e.name == actionTypeStr,
      orElse: () => SyncActionType.createBill);
}