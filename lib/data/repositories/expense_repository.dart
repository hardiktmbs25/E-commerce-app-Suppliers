import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../models/expense_model.dart';

class ExpenseRepository extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String get _vendorId => AuthService.to.vendorId;

  CollectionReference get _expenseCol => _firestore.collection(AppConstants.colExpenses);

  Future<void> addExpense(ExpenseModel expense) async {
    await _expenseCol.add(expense.toFirestore());
  }

  Stream<List<ExpenseModel>> watchExpenses(DateTime start, DateTime end) {
    return _expenseCol
        .where('vendorId', isEqualTo: _vendorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList());
  }
}