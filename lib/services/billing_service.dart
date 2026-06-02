// lib/services/billing_service.dart
import 'package:get/get.dart';

import '../core/utils/logger.dart';
import '../data/models/customer_model.dart';
import '../data/models/invoice_model.dart';
import '../data/models/delivery_model.dart';
import '../data/repositories/billing_repository.dart';
import 'connectivity_service.dart';
import 'local_storage_service.dart';
import 'billing_generation_service.dart';
import 'payment_service.dart';

class BillingService extends GetxService {
  final BillingGenerationService _billingGenService = Get.find<BillingGenerationService>();
  final PaymentService           _paymentService    = Get.find<PaymentService>();
  final BillingRepository        _billingRepo       = Get.find<BillingRepository>();
  final ConnectivityService      _connectivity      = Get.find<ConnectivityService>();

  /// Bridge method for recording customer payments.
  Future<bool> recordPayment({
    required String vendorId,
    required String customerId,
    required String customerName,
    required double amount,
    required String paymentMethodStr,
    String? billId,
    String? note,
  }) async {
    return _paymentService.recordPayment(
      vendorId: vendorId,
      customerId: customerId,
      customerName: customerName,
      amount: amount,
      paymentMethodStr: paymentMethodStr,
      invoiceId: billId,
      note: note,
    );
  }

  /// Bridge method for generating monthly invoices.
  Future<InvoiceModel?> generateMonthlyBill({
    required String vendorId,
    required CustomerModel customer,
    required int month,
    required int year,
    double discount = 0,
  }) async {
    return _billingGenService.generateInvoiceForCustomer(
      vendorId: vendorId,
      customer: customer,
      month: month,
      year: year,
      discount: discount,
    );
  }

  /// Scans all local invoices and marks unpaid/partially-paid ones as overdue
  /// if they are past their due date.
  /// Called on app start and scheduler jobs.
  Future<void> markOverdueBills(String vendorId) async {
    final now      = DateTime.now();
    final invoices = LocalStorageService.getBills();
    int count = 0;

    for (final inv in invoices) {
      // Only transition sent/partiallyPaid → overdue (not paid or draft)
      if ((inv.status == InvoiceStatus.sent ||
          inv.status == InvoiceStatus.partiallyPaid) &&
          now.isAfter(inv.dueDate)) {

        final updated = inv.copyWith(statusStr: InvoiceStatus.overdue.name);
        await LocalStorageService.saveBill(updated);
        count++;

        if (_connectivity.isOnline.value) {
          try {
            await _billingRepo.updateInvoiceStatus(
              vendorId:  vendorId,
              invoiceId: inv.id,
              statusStr: InvoiceStatus.overdue.name,
            );
          } catch (e) {
            AppLogger.e('BillingService: Failed to mark invoice ${inv.id} overdue in Firestore', e);
          }
        }
      }
    }

    if (count > 0) {
      AppLogger.i('BillingService: Marked $count invoices as overdue');
    }
  }

  /// Called after confirmation of delivery to record delivery status and update count.
  Future<void> onDeliveryMarkedDelivered({
    required String vendorId,
    required DeliveryModel delivery,
  }) async {
    // Delivery completions don't generate instant billing charges anymore,
    // because billing is compiled from successfully delivered deliveries!
    // We only log this for tracing.
    AppLogger.i('BillingService: Delivery confirmed for customer ${delivery.customerId} (${delivery.amount})');
  }

  /// Called when an extra order is placed.
  Future<void> onExtraOrderPlaced({
    required String vendorId,
    required DeliveryModel extraOrder,
  }) async {
    // Extra orders are automatically aggregated into the monthly invoice compilation!
    // No instant balance charging anymore (balance is compiled from invoices).
    AppLogger.i('BillingService: Extra order placed for customer ${extraOrder.customerId} (${extraOrder.amount})');
  }
}