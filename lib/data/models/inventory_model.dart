import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'inventory_model.g.dart';

@HiveType(typeId: AppConstants.tidInventoryModel)
class InventoryModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String vendorId;
  @HiveField(2) final String productName;
  @HiveField(3) final double currentStock;
  @HiveField(4) final String unit;
  @HiveField(5) final double lowStockAlert;
  @HiveField(6) final DateTime updatedAt;
  @HiveField(7) final String? category;

  InventoryModel({
    required this.id,
    required this.vendorId,
    required this.productName,
    this.currentStock = 0,
    this.unit = 'unit',
    this.lowStockAlert = 10,
    required this.updatedAt,
    this.category,
  });

  factory InventoryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return InventoryModel(
      id: doc.id,
      vendorId: d['vendorId'] ?? '',
      productName: d['productName'] ?? '',
      currentStock: (d['currentStock'] ?? 0).toDouble(),
      unit: d['unit'] ?? 'unit',
      lowStockAlert: (d['lowStockAlert'] ?? 10).toDouble(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: d['category'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId': vendorId,
    'productName': productName,
    'currentStock': currentStock,
    'unit': unit,
    'lowStockAlert': lowStockAlert,
    'updatedAt': FieldValue.serverTimestamp(),
    'category': category,
  };

  InventoryModel copyWith({
    double? currentStock,
    double? lowStockAlert,
    String? category,
  }) => InventoryModel(
    id: id,
    vendorId: vendorId,
    productName: productName,
    currentStock: currentStock ?? this.currentStock,
    unit: unit,
    lowStockAlert: lowStockAlert ?? this.lowStockAlert,
    updatedAt: DateTime.now(),
    category: category ?? this.category,
  );
}