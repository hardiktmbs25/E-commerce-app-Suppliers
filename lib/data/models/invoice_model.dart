// lib/data/models/invoice_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceStatus { draft, sent, paid, partiallyPaid, overdue }

class InvoiceLineItem {
  final String subscriptionId;
  final String description;  // '1L Milk × 28 days'
  final int deliveryCount;
  final double pricePerDelivery;
  final double extraCharges;
  final double discount;
  final double subtotal;

  const InvoiceLineItem({
    required this.subscriptionId,
    required this.description,
    required this.deliveryCount,
    required this.pricePerDelivery,
    this.extraCharges = 0,
    this.discount = 0,
    required this.subtotal,
  });

  factory InvoiceLineItem.fromMap(Map<String, dynamic> m) => InvoiceLineItem(
    subscriptionId: m['subscriptionId'] ?? '',
    description:    m['description'] ?? '',
    deliveryCount:  m['deliveryCount'] ?? 0,
    pricePerDelivery: (m['pricePerDelivery'] ?? 0).toDouble(),
    extraCharges:   (m['extraCharges'] ?? 0).toDouble(),
    discount:       (m['discount'] ?? 0).toDouble(),
    subtotal:       (m['subtotal'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'subscriptionId':  subscriptionId,
    'description':     description,
    'deliveryCount':   deliveryCount,
    'pricePerDelivery': pricePerDelivery,
    'extraCharges':    extraCharges,
    'discount':        discount,
    'subtotal':        subtotal,
  };
}

class InvoiceModel {
  final String id;
  final String vendorId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final int month;
  final int year;
  final String statusStr;
  final List<InvoiceLineItem> lineItems;
  final double subtotal;
  final double totalDiscount;
  final double extraCharges;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final DateTime generatedAt;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? notes;

  const InvoiceModel({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.month,
    required this.year,
    this.statusStr = 'draft',
    required this.lineItems,
    required this.subtotal,
    this.totalDiscount = 0,
    this.extraCharges = 0,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.pendingAmount,
    required this.generatedAt,
    required this.dueDate,
    this.paidAt,
    this.paymentMethod,
    this.notes,
  });

  InvoiceStatus get status => InvoiceStatus.values.firstWhere(
          (e) => e.name == statusStr, orElse: () => InvoiceStatus.draft);

  bool get isOverdue =>
      status != InvoiceStatus.paid && DateTime.now().isAfter(dueDate);

  String get invoiceNumber =>
      'INV-${year.toString().substring(2)}-${month.toString().padLeft(2, '0')}-${id.substring(0, 6).toUpperCase()}';

  String get monthName {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return InvoiceModel(
      id:              doc.id,
      vendorId:        d['vendorId'] ?? '',
      customerId:      d['customerId'] ?? '',
      customerName:    d['customerName'] ?? '',
      customerPhone:   d['customerPhone'] ?? '',
      customerAddress: d['customerAddress'] ?? '',
      month:           d['month'] ?? 1,
      year:            d['year'] ?? DateTime.now().year,
      statusStr:       d['status'] ?? 'draft',
      lineItems:       (d['lineItems'] as List<dynamic>? ?? [])
          .map((e) => InvoiceLineItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal:        (d['subtotal'] ?? 0).toDouble(),
      totalDiscount:   (d['totalDiscount'] ?? 0).toDouble(),
      extraCharges:    (d['extraCharges'] ?? 0).toDouble(),
      totalAmount:     (d['totalAmount'] ?? 0).toDouble(),
      paidAmount:      (d['paidAmount'] ?? 0).toDouble(),
      pendingAmount:   (d['pendingAmount'] ?? 0).toDouble(),
      generatedAt:     (d['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate:         (d['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt:          (d['paidAt'] as Timestamp?)?.toDate(),
      paymentMethod:   d['paymentMethod'],
      notes:           d['notes'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId':        vendorId,
    'customerId':      customerId,
    'customerName':    customerName,
    'customerPhone':   customerPhone,
    'customerAddress': customerAddress,
    'month':           month,
    'year':            year,
    'status':          statusStr,
    'lineItems':       lineItems.map((e) => e.toMap()).toList(),
    'subtotal':        subtotal,
    'totalDiscount':   totalDiscount,
    'extraCharges':    extraCharges,
    'totalAmount':     totalAmount,
    'paidAmount':      paidAmount,
    'pendingAmount':   pendingAmount,
    'generatedAt':     FieldValue.serverTimestamp(),
    'dueDate':         Timestamp.fromDate(dueDate),
    'paidAt':          paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    'paymentMethod':   paymentMethod,
    'notes':           notes,
  };
}