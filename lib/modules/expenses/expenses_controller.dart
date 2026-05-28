import 'package:get/get.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../../services/auth_service.dart';

class ExpensesController extends GetxController {
  final ExpenseRepository _expenseRepo = Get.find();

  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final RxDouble totalExpenses = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    expenses.bindStream(_expenseRepo.watchExpenses(start, end));
    
    ever(expenses, (list) {
      totalExpenses.value = list.fold(0, (sum, item) => sum + item.amount);
    });
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required ExpenseCategory category,
    String? notes,
  }) async {
    final newExpense = ExpenseModel(
      id: '',
      vendorId: AuthService.to.vendorId,
      title: title,
      amount: amount,
      categoryStr: category.name,
      date: DateTime.now(),
      notes: notes,
    );
    await _expenseRepo.addExpense(newExpense);
    Get.back();
  }
}