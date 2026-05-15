// lib/data/repositories/billing_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import '../../services/connectivity_service.dart';
import '../models/invoice_model.dart';
import '../models/delivery_model.dart';
import '../models/customer_model.dart';

class BillingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ConnectivityService _connectivity = Get.find<ConnectivityService>();

  String _invoiceCol(String vendorId) =>
      '${AppConstants.colVendors}/$vendorId/${AppConstants.colInvoices}';

  // ── Generate monthly invoice for a customer ────────────────────────────
  /// BILLING LOGIC:
  /// 1. Fetch all delivered deliveries for [customer] in [month]/[year]
  /// 2. Group by subscription → create InvoiceLineItems
  /// 3. Sum totals, apply discounts
  /// 4. Calculate due date (5 days after month end)
  /// 5. Write invoice to Firestore
  /// 6. Update customer.pendingAmount
  Future<Result<InvoiceModel>> generateMonthlyInvoice({
    required String vendorId,
    required CustomerModel customer,
    required int month,
    required int year,
  }) async {
    if (!_connectivity.isOnline.value) {
      return Result.failure(const NetworkFailure('Invoice generation requires internet.'));
    }

    try {
      // 1. Fetch deliveries for this customer this month
      final startDate = DateTime(year, month, 1);
      final endDate   = DateTime(year, month + 1, 0, 23, 59, 59);

      final snap = await _db
          .collection('${AppConstants.colVendors}/$vendorId/${AppConstants.colDeliveries}')
          .where('customerId',   isEqualTo: customer.id)
          .where('status',       isEqualTo: DeliveryStatus.delivered.name)
          .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final deliveries = snap.docs.map((d) => DeliveryModel.fromFirestore(d)).toList();
      if (deliveries.isEmpty) {
        return Result.failure(const ValidationFailure('No deliveries found for this period.'));
      }

      // 2. Group by subscription and build line items
      final Map<String, List<DeliveryModel>> grouped = {};
      for (final d in deliveries) {
        final key = d.subscriptionId ?? 'extra';
        grouped[key] = [...(grouped[key] ?? []), d];
      }

      final lineItems = grouped.entries.map((entry) {
        final items = entry.value;
        final totalAmount = items.fold(0.0, (sum, d) => sum + d.amount);
        final extraCharges = items
            .where((d) => d.isExtraOrder)
            .fold(0.0, (sum, d) => sum + d.amount);

        return InvoiceLineItem(
          subscriptionId:  entry.key,
          description:     '${items.first.serviceTypeStr.toUpperCase()} — ${items.length} deliveries',
          deliveryCount:   items.length,
          pricePerDelivery: items.first.amount,
          extraCharges:    extraCharges,
          subtotal:        totalAmount,
        );
      }).toList();

      // 3. Compute totals
      final subtotal     = lineItems.fold(0.0, (s, l) => s + l.subtotal);
      final extraCharges = lineItems.fold(0.0, (s, l) => s + l.extraCharges);
      final totalAmount  = subtotal; // Add tax logic here if needed

      // 4. Due date = 5th of next month
      final dueDate = DateTime(year, month + 1, AppConstants.billDueDays);

      // 5. Build invoice model
      final id = const Uuid().v4();
      final invoice = InvoiceModel(
        id:              id,
        vendorId:        vendorId,
        customerId:      customer.id,
        customerName:    customer.name,
        customerPhone:   customer.phone,
        customerAddress: customer.address,
        month:           month,
        year:            year,
        statusStr:       InvoiceStatus.sent.name,
        lineItems:       lineItems,
        subtotal:        subtotal,
        extraCharges:    extraCharges,
        totalAmount:     totalAmount,
        pendingAmount:   totalAmount,
        generatedAt:     DateTime.now(),
        dueDate:         dueDate,
      );

      // 6. Batch write invoice + update customer pending amount
      final batch = _db.batch();
      batch.set(
        _db.collection(_invoiceCol(vendorId)).doc(id),
        invoice.toFirestore(),
      );
      batch.update(
        _db.collection('${AppConstants.colVendors}/$vendorId/${AppConstants.colCustomers}')
            .doc(customer.id),
        {'pendingAmount': FieldValue.increment(totalAmount)},
      );
      await batch.commit();

      AppLogger.i('Invoice generated: $id for ${customer.name} ₹$totalAmount');
      return Result.success(invoice);
    } catch (e, s) {
      AppLogger.e('generateMonthlyInvoice error', e, s);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  // ── Record payment ─────────────────────────────────────────────────────
  Future<Result<void>> recordPayment({
    required String vendorId,
    required String invoiceId,
    required String customerId,
    required double amount,
    required String paymentMethod, // 'cash', 'upi', 'online'
    String? notes,
  }) async {
    try {
      final invoiceRef = _db.collection(_invoiceCol(vendorId)).doc(invoiceId);
      final customerRef = _db
          .collection('${AppConstants.colVendors}/$vendorId/${AppConstants.colCustomers}')
          .doc(customerId);

      final invoiceSnap = await invoiceRef.get();
      if (!invoiceSnap.exists) {
        return Result.failure(const FirestoreFailure('Invoice not found.'));
      }
      final invoice = InvoiceModel.fromFirestore(invoiceSnap);
      final newPaid    = invoice.paidAmount + amount;
      final newPending = invoice.totalAmount - newPaid;
      final newStatus  = newPending <= 0
          ? InvoiceStatus.paid.name
          : InvoiceStatus.partiallyPaid.name;

      final batch = _db.batch();
      batch.update(invoiceRef, {
        'paidAmount':    FieldValue.increment(amount),
        'pendingAmount': newPending,
        'status':        newStatus,
        'paidAt':        newPending <= 0 ? FieldValue.serverTimestamp() : null,
        'paymentMethod': paymentMethod,
        'notes':         notes,
        'updatedAt':     FieldValue.serverTimestamp(),
      });

      // Decrement customer pending amount
      batch.update(customerRef, {
        'pendingAmount': FieldValue.increment(-amount),
        'totalPaid':     FieldValue.increment(amount),
        'paymentStatus': newPending <= 0 ? 'paid' : 'pending',
        'updatedAt':     FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Also record in payment subcollection for history
      await _db
          .collection('${AppConstants.colVendors}/$vendorId/${AppConstants.colPayments}')
          .add({
        'invoiceId':     invoiceId,
        'customerId':    customerId,
        'vendorId':      vendorId,
        'amount':        amount,
        'paymentMethod': paymentMethod,
        'notes':         notes,
        'paidAt':        FieldValue.serverTimestamp(),
      });

      AppLogger.i('Payment recorded: ₹$amount for invoice $invoiceId');
      return const Result.success(null);
    } catch (e, s) {
      AppLogger.e('recordPayment error', e, s);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  // ── Watch invoices for a customer ─────────────────────────────────────
  Stream<List<InvoiceModel>> watchCustomerInvoices(
      String vendorId, String customerId) {
    return _db
        .collection(_invoiceCol(vendorId))
        .where('customerId', isEqualTo: customerId)
        .orderBy('generatedAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => InvoiceModel.fromFirestore(d)).toList());
  }

  // ── Vendor-level revenue aggregation ──────────────────────────────────
  Stream<Map<String, double>> watchMonthlyRevenue(
      String vendorId, int month, int year) {
    final start = DateTime(year, month, 1);
    final end   = DateTime(year, month + 1, 0);

    return _db
        .collection(_invoiceCol(vendorId))
        .where('month', isEqualTo: month)
        .where('year',  isEqualTo: year)
        .snapshots()
        .map((snap) {
      double totalRevenue  = 0;
      double paidRevenue   = 0;
      double pendingRevenue = 0;

      for (final doc in snap.docs) {
        final inv = InvoiceModel.fromFirestore(doc);
        totalRevenue   += inv.totalAmount;
        paidRevenue    += inv.paidAmount;
        pendingRevenue += inv.pendingAmount;
      }

      return {
        'total':   totalRevenue,
        'paid':    paidRevenue,
        'pending': pendingRevenue,
      };
    });
  }

  // ── Fetch pending invoices ─────────────────────────────────────────────
  Stream<List<InvoiceModel>> watchPendingInvoices(String vendorId) {
    return _db
        .collection(_invoiceCol(vendorId))
        .where('status', whereIn: [
      InvoiceStatus.sent.name,
      InvoiceStatus.partiallyPaid.name,
      InvoiceStatus.overdue.name,
    ])
        .orderBy('dueDate')
        .limit(50)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => InvoiceModel.fromFirestore(d)).toList());
  }
}