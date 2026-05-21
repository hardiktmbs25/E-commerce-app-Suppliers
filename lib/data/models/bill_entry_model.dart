// lib/data/models/bill_entry_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// One bill entry is created for every delivery marked as delivered.
/// These accumulate in vendors/{id}/bill_entries and are used to:
///   - Show customer's running balance
///   - Auto-generate monthly invoice line items
///   - Track what is billed vs unbilled
class BillEntryModel {
  final String id;
  final String vendorId;
  final String customerId;
  final String customerName;
  final String deliveryId;
  final String? subscriptionId;
  final String serviceType;
  final double quantity;
  final String unit;
  final double amount;
  final DateTime deliveredAt;
  final bool isBilled;         // true once included in a generated invoice
  final String? invoiceId;     // set when included in an invoice
  final bool isExtraOrder;
  final DateTime createdAt;

  BillEntryModel({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    required this.deliveryId,
    this.subscriptionId,
    required this.serviceType,
    required this.quantity,
    required this.unit,
    required this.amount,
    required this.deliveredAt,
    this.isBilled = false,
    this.invoiceId,
    this.isExtraOrder = false,
    required this.createdAt,
  });

  factory BillEntryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BillEntryModel(
      id:             doc.id,
      vendorId:       d['vendorId'] ?? '',
      customerId:     d['customerId'] ?? '',
      customerName:   d['customerName'] ?? '',
      deliveryId:     d['deliveryId'] ?? '',
      subscriptionId: d['subscriptionId'],
      serviceType:    d['serviceType'] ?? '',
      quantity:       (d['quantity'] ?? 1).toDouble(),
      unit:           d['unit'] ?? 'unit',
      amount:         (d['amount'] ?? 0).toDouble(),
      deliveredAt:    (d['deliveredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isBilled:       d['isBilled'] ?? false,
      invoiceId:      d['invoiceId'],
      isExtraOrder:   d['isExtraOrder'] ?? false,
      createdAt:      (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId':       vendorId,
    'customerId':     customerId,
    'customerName':   customerName,
    'deliveryId':     deliveryId,
    'subscriptionId': subscriptionId,
    'serviceType':    serviceType,
    'quantity':       quantity,
    'unit':           unit,
    'amount':         amount,
    'deliveredAt':    Timestamp.fromDate(deliveredAt),
    'isBilled':       isBilled,
    'invoiceId':      invoiceId,
    'isExtraOrder':   isExtraOrder,
    'createdAt':      Timestamp.fromDate(createdAt),
    'updatedAt':      FieldValue.serverTimestamp(),
  };
}