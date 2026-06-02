// lib/services/ledger_service.dart
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../data/models/ledger_entry_model.dart';
import '../data/models/sync_action_model.dart';
import '../data/repositories/billing_repository.dart';
import 'connectivity_service.dart';
import 'local_storage_service.dart';

class LedgerService extends GetxService {
  final BillingRepository _billingRepo = Get.find<BillingRepository>();
  final ConnectivityService _connectivity = Get.find<ConnectivityService>();

  /// Creates a ledger entry, computes the new running balance After,
  /// saves it locally, and syncs/queues it.
  Future<LedgerEntryModel> createEntry({
    required String vendorId,
    required String customerId,
    required LedgerEntryType type,
    required double amount,
    required String description,
    String? referenceId,
  }) async {
    final currentBalance = LocalStorageService.getBalanceForCustomer(customerId);
    final balanceAfter = currentBalance + amount;

    final entry = LedgerEntryModel(
      id: const Uuid().v4(),
      vendorId: vendorId,
      customerId: customerId,
      typeStr: type.name,
      amount: amount,
      balanceAfter: balanceAfter,
      description: description,
      referenceId: referenceId,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    // 1. Save locally
    await LocalStorageService.saveLedgerEntry(entry);

    // 2. Sync to Firestore
    if (_connectivity.isOnline.value) {
      try {
        await _billingRepo.writeLedgerEntry(vendorId: vendorId, entry: entry);
        // Mark as synced locally
        final syncedEntry = LedgerEntryModel(
          id: entry.id,
          vendorId: entry.vendorId,
          customerId: entry.customerId,
          typeStr: entry.typeStr,
          amount: entry.amount,
          balanceAfter: entry.balanceAfter,
          description: entry.description,
          referenceId: entry.referenceId,
          createdAt: entry.createdAt,
          isSynced: true,
        );
        await LocalStorageService.saveLedgerEntry(syncedEntry);
      } catch (e) {
        AppLogger.e('LedgerService: Firestore sync failed, queuing offline', e);
        await _enqueue(vendorId, entry);
      }
    } else {
      await _enqueue(vendorId, entry);
    }

    AppLogger.i('Ledger entry created: ${type.name} of ₹$amount for $customerId. Balance: ₹$balanceAfter');
    return entry;
  }

  Future<void> _enqueue(String vendorId, LedgerEntryModel entry) async {
    // IMPORTANT: Hive payloads must not contain Firestore Timestamp objects.
    // Store createdAt as ISO-8601 string; SyncService converts to Timestamp on write.
    await LocalStorageService.enqueueSyncAction(SyncActionModel(
      id:            const Uuid().v4(),
      actionTypeStr: SyncActionType.createLedgerEntry.name,
      collection:    '${AppConstants.colVendors}/$vendorId/${AppConstants.colLedger}',
      documentId:    entry.id,
      payload:       {
        'vendorId':     entry.vendorId,
        'customerId':   entry.customerId,
        'type':         entry.typeStr,
        'amount':       entry.amount,
        'balanceAfter': entry.balanceAfter,
        'description':  entry.description,
        'referenceId':  entry.referenceId ?? '',
        'createdAt':    entry.createdAt.toIso8601String(), // ISO string — safe for Hive
      },
      createdAt: DateTime.now(),
    ));
  }
}