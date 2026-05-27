// lib/data/models/ledger_entry_model.dart
//
// One ledger entry per business event that affects a customer's balance.
// Stored at: vendors/{vendorId}/ledger/{entryId}
//
// Entry types:
//   charge   – delivery delivered (increases balance owed)
//   extra    – extra order (increases balance owed)
//   payment  – payment received (decreases balance owed)
//   discount – vendor applies discount (decreases balance owed)
//   carryFwd – opening balance carried from previous period
//
// balanceAfter is the running total AFTER this entry is applied.
// It is computed by BillingService when writing and stored for fast UI display.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
part 'ledger_entry_model.g.dart';

enum LedgerEntryType { charge, extra, payment, discount, carryFwd }

@HiveType(typeId: AppConstants.tidLedgerEntryModel)
class LedgerEntryModel extends HiveObject {
  @HiveField(0)  final String id;
  @HiveField(1)  final String vendorId;
  @HiveField(2)  final String customerId;
  @HiveField(3)  final String typeStr;          // LedgerEntryType.name
  /// Positive = money owed by customer; negative = money received.
  @HiveField(4)  final double amount;
  /// Running total after this entry. Positive = customer owes this much.
  @HiveField(5)  final double balanceAfter;
  @HiveField(6)  final String description;      // human-readable e.g. "Milk – 1 Litre"
  @HiveField(7)  final String? referenceId;     // deliveryId, paymentId, billId, etc.
  @HiveField(8)  final DateTime createdAt;
  @HiveField(9)  final bool isSynced;

  LedgerEntryModel({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.typeStr,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    this.referenceId,
    required this.createdAt,
    this.isSynced = true,
  });

  LedgerEntryType get entryType => LedgerEntryType.values.firstWhere(
          (e) => e.name == typeStr, orElse: () => LedgerEntryType.charge);

  bool get isDebit  => entryType == LedgerEntryType.charge ||
      entryType == LedgerEntryType.extra  ||
      entryType == LedgerEntryType.carryFwd;
  bool get isCredit => entryType == LedgerEntryType.payment ||
      entryType == LedgerEntryType.discount;

  factory LedgerEntryModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return LedgerEntryModel(
      id:           doc.id,
      vendorId:     _s(d['vendorId']),
      customerId:   _s(d['customerId']),
      typeStr:      _s(d['type'], 'charge'),
      amount:       _d(d['amount']),
      balanceAfter: _d(d['balanceAfter']),
      description:  _s(d['description']),
      referenceId:  d['referenceId'] as String?,
      createdAt:    (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSynced:     true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId':    vendorId,
    'customerId':  customerId,
    'type':        typeStr,
    'amount':      amount,
    'balanceAfter': balanceAfter,
    'description': description,
    'referenceId': referenceId,
    'createdAt':   Timestamp.fromDate(createdAt),
    'updatedAt':   FieldValue.serverTimestamp(),
  };

  static String _s(dynamic v, [String fb = '']) => v is String ? v : fb;
  static double _d(dynamic v, [double fb = 0.0]) {
    if (v is double) return v;
    if (v is int)    return v.toDouble();
    return fb;
  }
}