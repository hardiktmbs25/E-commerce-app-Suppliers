import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'expense_model.g.dart';

enum ExpenseCategory { fuel, salary, maintenance, electricity, purchase, food, other }

@HiveType(typeId: AppConstants.tidExpenseModel)
class ExpenseModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String vendorId;
  @HiveField(2) final String title;
  @HiveField(3) final double amount;
  @HiveField(4) final String categoryStr;
  @HiveField(5) final DateTime date;
  @HiveField(6) final String? notes;
  @HiveField(7) final String? staffId; // if it's a salary expense

  ExpenseModel({
    required this.id,
    required this.vendorId,
    required this.title,
    required this.amount,
    required this.categoryStr,
    required this.date,
    this.notes,
    this.staffId,
  });

  ExpenseCategory get category => ExpenseCategory.values.firstWhere(
    (e) => e.name == categoryStr,
    orElse: () => ExpenseCategory.other,
  );

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      vendorId: d['vendorId'] ?? '',
      title: d['title'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(),
      categoryStr: d['category'] ?? 'other',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: d['notes'],
      staffId: d['staffId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId': vendorId,
    'title': title,
    'amount': amount,
    'category': categoryStr,
    'date': Timestamp.fromDate(date),
    'notes': notes,
    'staffId': staffId,
  };
}