import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../data/models/customer_model.dart';
import '../data/models/wallet_transaction_model.dart';
import '../data/repositories/customer_repository.dart';

class WalletService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CustomerRepository _customerRepo = Get.find();

  Future<void> addBalance(CustomerModel customer, double amount, String description) async {
    final transaction = WalletTransactionModel(
      id: '',
      customerId: customer.id,
      amount: amount,
      type: TransactionType.credit,
      description: description,
      timestamp: DateTime.now(),
    );

    await _firestore.runTransaction((tx) async {
      final customerDoc = _firestore.collection('customers').doc(customer.id);
      final newBalance = customer.walletBalance + amount;
      
      tx.set(_firestore.collection('wallet_transactions').doc(), transaction.toFirestore());
      tx.update(customerDoc, {'walletBalance': newBalance});
    });
  }

  Future<void> deductBalance(CustomerModel customer, double amount, String description, {String? refId}) async {
    final transaction = WalletTransactionModel(
      id: '',
      customerId: customer.id,
      amount: amount,
      type: TransactionType.debit,
      description: description,
      timestamp: DateTime.now(),
      referenceId: refId,
    );

    await _firestore.runTransaction((tx) async {
      final customerDoc = _firestore.collection('customers').doc(customer.id);
      final newBalance = customer.walletBalance - amount;
      
      tx.set(_firestore.collection('wallet_transactions').doc(), transaction.toFirestore());
      tx.update(customerDoc, {'walletBalance': newBalance});
    });
  }
}