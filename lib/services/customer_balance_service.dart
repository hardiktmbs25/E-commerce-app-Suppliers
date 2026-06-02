// lib/services/customer_balance_service.dart
import 'package:get/get.dart';

import '../core/utils/logger.dart';
import '../data/models/invoice_model.dart';
import '../data/repositories/billing_repository.dart';
import 'connectivity_service.dart';
import 'local_storage_service.dart';

class CustomerBalanceService extends GetxService {
  final BillingRepository _billingRepo = Get.find<BillingRepository>();
  final ConnectivityService _connectivity = Get.find<ConnectivityService>();

  /// Recalculates customer balance strictly by aggregating all invoices and all payments:
  /// pendingAmount = sum(invoices) - sum(payments)
  /// Saves it locally and triggers Firestore updates.
  Future<double> recalculateCustomerBalance({
    required String vendorId,
    required String customerId,
  }) async {
    // 1. Get all local cached invoices
    final invoices = LocalStorageService.getBillsForCustomer(customerId)
        .where((inv) => inv.status != InvoiceStatus.draft) // exclude draft invoices from real dues
        .toList();

    // 2. Get all local payments
    final payments = LocalStorageService.getPaymentsForCustomer(customerId);

    // 3. Compute totals
    final double totalInvoiced = invoices.fold(0.0, (sum, inv) => sum + inv.totalAmount);
    final double totalPaid = payments.fold(0.0, (sum, pay) => sum + pay.amount);
    final double pendingAmount = (totalInvoiced - totalPaid).clamp(0.0, double.infinity);

    // 4. Update customer local cache
    final customer = LocalStorageService.getCustomer(customerId);
    if (customer != null) {
      final updated = customer.copyWith(
        pendingAmount: pendingAmount,
        totalPaid: totalPaid,
        paymentStatusStr: pendingAmount <= 0 ? 'paid' : 'pending',
      );
      await LocalStorageService.saveCustomer(updated);

      // 5. Update Firestore absolute pending amount
      if (_connectivity.isOnline.value) {
        try {
          await _billingRepo.updateCustomerPendingAbsolute(
            vendorId: vendorId,
            customerId: customerId,
            pendingAmount: pendingAmount,
          );
        } catch (e) {
          AppLogger.e('CustomerBalanceService: Firestore absolute update failed', e);
        }
      }
    }

    AppLogger.i('Recalculated balance for customer $customerId: Invoiced: ₹$totalInvoiced, Paid: ₹$totalPaid, Due: ₹$pendingAmount');
    return pendingAmount;
  }
}
