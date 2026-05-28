import 'package:get/get.dart';
import '../../data/repositories/expense_repository.dart';
import 'expenses_controller.dart';

class ExpensesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExpenseRepository>(() => ExpenseRepository());
    Get.lazyPut<ExpensesController>(() => ExpensesController());
  }
}