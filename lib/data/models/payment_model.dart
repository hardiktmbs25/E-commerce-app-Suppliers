// lib/data/models/payment_model.dart
// Stored at: vendors/{vendorId}/payments/{paymentId}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
part 'payment_model.g.dart';

enum PaymentMethod { cash, upi, online, cheque, other }

@HiveType(typeId: AppConstants.tidPaymentModel)
class PaymentModel extends HiveObject {
  @HiveField(0)  final String id;
  @HiveField(1)  final String vendorId;
  @HiveField(2)  final String customerId;
  @HiveField(3)  final String customerName;
  @HiveField(4)  final String? billId;        // null for ad-hoc daily payments
  @HiveField(5)  final double amount;
  @HiveField(6)  final String paymentMethodStr; // PaymentMethod.name
  @HiveField(7)  final DateTime paidAt;
  @HiveField(8)  final String? note;
  @HiveField(9)  final bool isSynced;
  @HiveField(10) final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    this.billId,
    required this.amount,
    this.paymentMethodStr = 'cash',
    required this.paidAt,
    this.note,
    this.isSynced = true,
    required this.createdAt,
  });

  PaymentMethod get paymentMethod => PaymentMethod.values.firstWhere(
          (e) => e.name == paymentMethodStr, orElse: () => PaymentMethod.cash);

  String get methodLabel {
    switch (paymentMethod) {
      case PaymentMethod.cash:   return 'Cash';
      case PaymentMethod.upi:    return 'UPI';
      case PaymentMethod.online: return 'Online';
      case PaymentMethod.cheque: return 'Cheque';
      case PaymentMethod.other:  return 'Other';
    }
  }

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return PaymentModel(
      id:                doc.id,
      vendorId:          _s(d['vendorId']),
      customerId:        _s(d['customerId']),
      customerName:      _s(d['customerName']),
      billId:            d['billId'] as String?,
      amount:            _d(d['amount']),
      paymentMethodStr:  _s(d['paymentMethod'], 'cash'),
      paidAt:            (d['paidAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note:              d['note'] as String?,
      isSynced:          true,
      createdAt:         (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId':     vendorId,
    'customerId':   customerId,
    'customerName': customerName,
    'billId':       billId,
    'amount':       amount,
    'paymentMethod': paymentMethodStr,
    'paidAt':       Timestamp.fromDate(paidAt),
    'note':         note,
    'createdAt':    Timestamp.fromDate(createdAt),
    'updatedAt':    FieldValue.serverTimestamp(),
  };

  static String _s(dynamic v, [String fb = '']) => v is String ? v : fb;
  static double _d(dynamic v, [double fb = 0.0]) {
    if (v is double) return v;
    if (v is int)    return v.toDouble();
    return fb;
  }
}