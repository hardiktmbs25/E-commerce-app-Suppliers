import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'route_model.g.dart';

@HiveType(typeId: AppConstants.tidRouteModel)
class RouteModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String vendorId;
  @HiveField(2) final String name;
  @HiveField(3) final String? deliveryBoyId;
  @HiveField(4) final String? deliveryBoyName;
  @HiveField(5, defaultValue: []) final List<String> customerIds;
  @HiveField(6, defaultValue: true) final bool isActive;
  @HiveField(7) final DateTime createdAt;
  @HiveField(8) final DateTime updatedAt;
  @HiveField(9, defaultValue: 0) final int totalCustomers;
  @HiveField(10) final String? areaName;

  RouteModel({
    required this.id,
    required this.vendorId,
    required this.name,
    this.deliveryBoyId,
    this.deliveryBoyName,
    this.customerIds = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.totalCustomers = 0,
    this.areaName,
  });

  factory RouteModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RouteModel(
      id: doc.id,
      vendorId: d['vendorId'] ?? '',
      name: d['name'] ?? '',
      deliveryBoyId: d['deliveryBoyId'],
      deliveryBoyName: d['deliveryBoyName'],
      customerIds: List<String>.from(d['customerIds'] ?? []),
      isActive: d['isActive'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalCustomers: d['totalCustomers'] ?? 0,
      areaName: d['areaName'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId': vendorId,
    'name': name,
    'deliveryBoyId': deliveryBoyId,
    'deliveryBoyName': deliveryBoyName,
    'customerIds': customerIds,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
    'totalCustomers': totalCustomers,
    'areaName': areaName,
  };

  RouteModel copyWith({
    String? name,
    String? deliveryBoyId,
    String? deliveryBoyName,
    List<String>? customerIds,
    bool? isActive,
    int? totalCustomers,
    String? areaName,
  }) => RouteModel(
    id: id,
    vendorId: vendorId,
    name: name ?? this.name,
    deliveryBoyId: deliveryBoyId ?? this.deliveryBoyId,
    deliveryBoyName: deliveryBoyName ?? this.deliveryBoyName,
    customerIds: customerIds ?? this.customerIds,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    totalCustomers: totalCustomers ?? this.totalCustomers,
    areaName: areaName ?? this.areaName,
  );
}