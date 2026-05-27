// lib/data/models/invoice_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'invoice_model.g.dart';

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

@HiveType(typeId: AppConstants.tidBillingModel) // Reuses tidBillingModel (5) for unified storage
class InvoiceModel extends HiveObject {
  @HiveField(0)  final String id;
  @HiveField(1)  final String vendorId;
  @HiveField(2)  final String customerId;
  @HiveField(3)  final String customerName;
  @HiveField(4)  final String customerPhone;
  @HiveField(5)  final String customerAddress;
  @HiveField(6)  final int month;
  @HiveField(7)  final int year;
  @HiveField(8)  final String statusStr;
  @HiveField(9)  final List<Map<String, dynamic>> rawLineItems;
  @HiveField(10) final double subtotal;
  @HiveField(11) final double totalDiscount;
  @HiveField(12) final double extraCharges;
  @HiveField(13) final double totalAmount;
  @HiveField(14) final double paidAmount;
  @HiveField(15) final double pendingAmount;
  @HiveField(16) final DateTime generatedAt;
  @HiveField(17) final DateTime dueDate;
  @HiveField(18) final DateTime? paidAt;
  @HiveField(19) final String? paymentMethod;
  @HiveField(20) final String? notes;
  @HiveField(21) final List<String> deliveryIds;

  final List<InvoiceLineItem> lineItems;

  InvoiceModel({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.month,
    required this.year,
    this.statusStr = 'draft',
    List<InvoiceLineItem>? lineItems,
    List<Map<String, dynamic>>? rawLineItems,
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
    this.deliveryIds = const [],
  })  : lineItems = lineItems ??
      (rawLineItems?.map((e) => InvoiceLineItem.fromMap(Map<String, dynamic>.from(e))).toList() ?? []),
        rawLineItems = rawLineItems ??
            (lineItems?.map((e) => e.toMap()).toList() ?? const []);

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

  int get totalDeliveries => deliveryIds.length;
  String get invoiceMonth => '$monthName $year';

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    final listRaw = d['lineItems'] as List<dynamic>? ?? [];
    final rawItems = listRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

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
      rawLineItems:    rawItems,
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
      deliveryIds:     List<String>.from(d['deliveryIds'] ?? []),
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
    'lineItems':       rawLineItems,
    'subtotal':        subtotal,
    'totalDiscount':   totalDiscount,
    'extraCharges':    extraCharges,
    'totalAmount':     totalAmount,
    'paidAmount':      paidAmount,
    'pendingAmount':   pendingAmount,
    'generatedAt':     Timestamp.fromDate(generatedAt),
    'dueDate':         Timestamp.fromDate(dueDate),
    'paidAt':          paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    'paymentMethod':   paymentMethod,
    'notes':           notes,
    'deliveryIds':     deliveryIds,
    'updatedAt':       FieldValue.serverTimestamp(),
  };

  InvoiceModel copyWith({
    String? statusStr,
    double? paidAmount,
    double? pendingAmount,
    DateTime? paidAt,
    String? paymentMethod,
    String? notes,
  }) => InvoiceModel(
    id:              id,
    vendorId:        vendorId,
    customerId:      customerId,
    customerName:    customerName,
    customerPhone:   customerPhone,
    customerAddress: customerAddress,
    month:           month,
    year:            year,
    statusStr:       statusStr ?? this.statusStr,
    rawLineItems:    rawLineItems,
    subtotal:        subtotal,
    totalDiscount:   totalDiscount,
    extraCharges:    extraCharges,
    totalAmount:     totalAmount,
    paidAmount:      paidAmount ?? this.paidAmount,
    pendingAmount:   pendingAmount ?? this.pendingAmount,
    generatedAt:     generatedAt,
    dueDate:         dueDate,
    paidAt:          paidAt ?? this.paidAt,
    paymentMethod:   paymentMethod ?? this.paymentMethod,
    notes:           notes ?? this.notes,
    deliveryIds:     deliveryIds,
  );
}