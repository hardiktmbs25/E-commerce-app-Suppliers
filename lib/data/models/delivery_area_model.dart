// lib/data/models/delivery_area_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// A delivery area defined by the vendor.
/// Stored at: vendors/{vendorId}/areas/{areaId}
class DeliveryAreaModel {
  final String id;
  final String vendorId;
  final String name;         // e.g. "Andheri West", "Bandra East"
  final String? pincode;
  final String? city;
  final bool isActive;
  final DateTime createdAt;

  const DeliveryAreaModel({
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