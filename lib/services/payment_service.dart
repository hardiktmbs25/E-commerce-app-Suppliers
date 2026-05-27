// lib/services/payment_service.dart
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../data/models/invoice_model.dart';
import '../data/models/payment_model.dart';
import '../data/models/ledger_entry_model.dart';
import '../data/models/sync_action_model.dart';
import 'customer_balance_service.dart';
import 'ledger_service.dart';
import 'connectivity_service.dart';
import 'local_storage_service.dart';

class PaymentService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ConnectivityService _connectivity = Get.find<ConnectivityService>();
  final LedgerService _ledgerService = Get.find<LedgerService>();
  final CustomerBalanceService _balanceService = Get.find<CustomerBalanceService>();

  String _paymentsCol(String vendorId) =>
      '${AppConstants.colVendors}/$vendorId/${AppConstants.colPayments}';

  String _invoiceCol(String vendorId) =>
      '${AppConstants.colVendors}/$vendorId/${AppConstants.colInvoices}';

  /// Records a customer payment. If no invoiceId is linked, applies
  /// a cascading lump-sum credit to the oldest unpaid invoices first.
  Future<bool> recordPayment({
    required String vendorId,
    required String customerId,
    required String customerName,
    required double amount,
    required String paymentMethodStr,
    String? invoiceId,
    String? note,
  }) async {
    if (amount <= 0) {
      AppLogger.w('PaymentService: Payment amount must be greater than zero');
      return false;
    }

    final now = DateTime.now();
    final paymentId = const Uuid().v4();

    // 1. Build payment record
    final payment = PaymentModel(
      id: paymentId,
      vendorId: vendorId,
      customerId: customerId,
      customerName: customerName,
      billId: invoiceId,
      amount: amount,
      paymentMethodStr: paymentMethodStr,
      paidAt: now,
      note: note,
      isSynced: _connectivity.isOnline.value,
      createdAt: now,
    );

    // Save payment locally
    await LocalStorageService.savePayment(payment);

    // 2. Resolve target invoices to update
    final List<InvoiceModel> invoicesToUpdate = [];
    double remainingPayment = amount;

    if (invoiceId != null && invoiceId.isNotEmpty) {
      // Direct payment to a single invoice
      final invoices = LocalStorageService.getBillsForCustomer(customerId);
      final inv = invoices.firstWhereOrNull((i) => i.id == invoiceId);
      if (inv != null) {
        final newPaid = inv.paidAmount + amount;
        final newPending = (inv.totalAmount - newPaid).clamp(0.0, double.infinity);
        final newStatus = newPending <= 0.0 ? InvoiceStatus.paid.name : InvoiceStatus.partiallyPaid.name;
        
        invoicesToUpdate.add(inv.copyWith(
          paidAmount: newPaid,
          pendingAmount: newPending,
          statusStr: newStatus,
          paidAt: newPending <= 0.0 ? now : null,
          paymentMethod: paymentMethodStr,
        ));
      }
    } else {
      // Cascading payment logic (lump sum applied to oldest unpaid invoices first!)
      final unpaidInvoices = LocalStorageService.getBillsForCustomer(customerId)
          .where((i) => i.status != InvoiceStatus.paid && i.status != InvoiceStatus.draft)
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Oldest first

      for (final inv in unpaidInvoices) {
        if (remainingPayment <= 0) break;
        final double pendingAmount = inv.pendingAmount;
        
        if (remainingPayment >= pendingAmount) {
          // Fully pay off this invoice
          invoicesToUpdate.add(inv.copyWith(
            paidAmount: inv.totalAmount,
            pendingAmount: 0.0,
            statusStr: InvoiceStatus.paid.name,
            paidAt: now,
            paymentMethod: paymentMethodStr,
          ));
          remainingPayment -= pendingAmount;
        } else {
          // Partially pay off this invoice
          final newPaid = inv.paidAmount + remainingPayment;
          final newPending = inv.pendingAmount - remainingPayment;
          invoicesToUpdate.add(inv.copyWith(
            paidAmount: newPaid,
            pendingAmount: newPending,
            statusStr: InvoiceStatus.partiallyPaid.name,
            paymentMethod: paymentMethodStr,
          ));
          remainingPayment = 0.0;
        }
      }
    }

    // Save updated invoices locally
    for (final inv in invoicesToUpdate) {
      await LocalStorageService.saveBill(inv);
    }

    // Sync Firestore if online
    if (_connectivity.isOnline.value) {
      try {
        final batch = _db.batch();
        batch.set(
          _db.collection(_paymentsCol(vendorId)).doc(paymentId),
          payment.toFirestore(),
        );

        for (final inv in invoicesToUpdate) {
          batch.set(
            _db.collection(_invoiceCol(vendorId)).doc(inv.id),
            inv.toFirestore(),
          );
        }
        await batch.commit();
      } catch (e) {
        AppLogger.e('PaymentService: Firestore sync failed, queuing offline', e);
        await _enqueueOfflinePayment(vendorId, payment, invoicesToUpdate);
      }
    } else {
      await _enqueueOfflinePayment(vendorId, payment, invoicesToUpdate);
    }

    // 3. Create credit ledger entry (credits are stored as negative amounts)
    final methodLabel = _methodLabel(paymentMethodStr);
    await _ledgerService.createEntry(
      vendorId: vendorId,
      customerId: customerId,
      type: LedgerEntryType.payment, // credit
      amount: -amount,
      description: 'Payment received – $methodLabel${note != null ? " ($note)" : ""}',
      referenceId: paymentId,
    );

    // 4. Recalculate customer due balance strictly
    await _balanceService.recalculateCustomerBalance(
      vendorId: vendorId,
      customerId: customerId,
    );

    AppLogger.i('Payment processed: ₹$amount recorded for $customerName');
    return true;
  }

  Future<void> _enqueueOfflinePayment(String vendorId, PaymentModel payment, List<InvoiceModel> invoices) async {
    // Queue payment record sync
    await LocalStorageService.enqueueSyncAction(SyncActionModel(
      id: const Uuid().v4(),
      actionTypeStr: SyncActionType.recordBillPayment.name,
      collection: _paymentsCol(vendorId),
      documentId: payment.id,
      payload: payment.toFirestore(),
      createdAt: DateTime.now(),
    ));

    // Queue updates for individual invoices
    for (final inv in invoices) {
      await LocalStorageService.enqueueSyncAction(SyncActionModel(
        id: const Uuid().v4(),
        actionTypeStr: SyncActionType.createBill.name,
        collection: _invoiceCol(vendorId),
        documentId: inv.id,
        payload: inv.toFirestore(),
        createdAt: DateTime.now(),
      ));
    }
  }

  String _methodLabel(String key) {
    switch (key) {
      case 'upi':    return 'UPI';
      case 'online': return 'Online';
      case 'cheque': return 'Cheque';
      default:       return 'Cash';
    }
  }
}
