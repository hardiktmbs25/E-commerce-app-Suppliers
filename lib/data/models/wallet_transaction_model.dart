import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { credit, debit }

class WalletTransactionModel {
  final String id;
  final String customerId;
  final double amount;
  final TransactionType type;
  final String description;
  final DateTime timestamp;
  final String? referenceId; // e.g. deliveryId or invoiceId

  WalletTransactionModel({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    required this.description,
    required this.timestamp,
    this.referenceId,
  });

  factory WalletTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WalletTransactionModel(
      id: doc.id,
      customerId: d['customerId'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(),
      type: d['type'] == 'credit' ? TransactionType.credit : TransactionType.debit,
      description: d['description'] ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      referenceId: d['referenceId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'customerId': customerId,
    'amount': amount,
    'type': type.name,
    'description': description,
    'timestamp': Timestamp.fromDate(timestamp),
    'referenceId': referenceId,
  };
}