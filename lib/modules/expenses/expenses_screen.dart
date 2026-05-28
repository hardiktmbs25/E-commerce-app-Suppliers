import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/expense_model.dart';
import 'expenses_controller.dart';

class ExpensesScreen extends GetView<ExpensesController> {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('expenses'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 32, color: AppColors.primary),
            onPressed: () => _showAddExpenseDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: Obx(() {
              if (controller.expenses.isEmpty) {
                return const Center(child: Text('No expenses recorded this month'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.expenses.length,
                itemBuilder: (context, index) {
                  final expense = controller.expenses[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: _getCategoryIcon(expense.category),
                      title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(expense.categoryStr.toUpperCase()),
                      trailing: Text(
                        '₹${expense.amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientRed),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('TOTAL EXPENSES (THIS MONTH)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Obx(() => Text(
            '₹${controller.totalExpenses.value.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          )),
        ],
      ),
    );
  }

  Widget _getCategoryIcon(ExpenseCategory category) {
    IconData icon;
    switch (category) {
      case ExpenseCategory.fuel: icon = Icons.local_gas_station; break;
      case ExpenseCategory.salary: icon = Icons.payments; break;
      case ExpenseCategory.maintenance: icon = Icons.build; break;
      case ExpenseCategory.electricity: icon = Icons.lightbulb; break;
      case ExpenseCategory.purchase: icon = Icons.shopping_bag; break;
      default: icon = Icons.more_horiz;
    }
    return CircleAvatar(backgroundColor: AppColors.surfaceVariant, child: Icon(icon, color: AppColors.primary));
  }

  void _showAddExpenseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    ExpenseCategory selectedCategory = ExpenseCategory.other;

    Get.dialog(
      AlertDialog(
        title: const Text('Add New Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Expense Title')),
            const SizedBox(height: 12),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount (₹)'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ExpenseCategory.values.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat.name.toUpperCase()));
              }).toList(),
              onChanged: (val) { if (val != null) selectedCategory = val; },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                controller.addExpense(
                  title: titleController.text,
                  amount: double.tryParse(amountController.text) ?? 0,
                  category: selectedCategory,
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}