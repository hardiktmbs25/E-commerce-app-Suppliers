// lib/data/models/delivery_area_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'delivery_area_model.g.dart';

/// A delivery area defined by the vendor.
/// Stored at: vendors/{vendorId}/areas/{areaId}
@HiveType(typeId: AppConstants.tidDeliveryAreaModel)
class DeliveryAreaModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String vendorId;
  @HiveField(2) final String name;         // e.g. "Andheri West", "Bandra East"
  @HiveField(3) final String? pincode;
  @HiveField(4) final String? city;
  @HiveField(5) final bool isActive;
  @HiveField(6) final DateTime createdAt;

  DeliveryAreaModel({
    required this.id,
    required this.vendorId,
    required this.name,
    this.pincode,
    this.city,
    this.isActive = true,
    required this.createdAt,
  });


  factory DeliveryAreaModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DeliveryAreaModel(
      id:        doc.id,
      vendorId:  d['vendorId'] ?? '',
      name:      d['name'] ?? '',
      pincode:   d['pincode'],
      city:      d['city'],
      isActive:  d['isActive'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId':  vendorId,
    'name':      name,
    'pincode':   pincode,
    'city':      city,
    'isActive':  isActive,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}