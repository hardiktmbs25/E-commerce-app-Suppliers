// lib/data/models/plan_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// A global plan template that a vendor defines.
/// Stored at: vendors/{vendorId}/plans/{planId}
class PlanModel {
  final String id;
  final String vendorId;
  final String name;           // e.g. "Silver Milk Plan"
  final String serviceType;    // milk | water | newspaper | tiffin | grocery | custom
  final String frequencyStr;   // daily | alternateDay | weekdays | weekends | weekly | custom
  final double quantity;       // e.g. 1.5
  final String unit;           // litre | packet | copy | box | kg | piece
  final double pricePerUnit;
  final double pricePerDelivery; // quantity × pricePerUnit
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlanModel({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.serviceType,
    this.frequencyStr = 'daily',
    required this.quantity,
    this.unit = 'unit',
    required this.pricePerUnit,
    required this.pricePerDelivery,
    this.description = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlanModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PlanModel(
      id:               doc.id,
      vendorId:         d['vendorId'] ?? '',
      name:             d['name'] ?? '',
      serviceType:      d['serviceType'] ?? 'custom',
      frequencyStr:     d['frequency'] ?? 'daily',
      quantity:         (d['quantity'] ?? 1).toDouble(),
      unit:             d['unit'] ?? 'unit',
      pricePerUnit:     (d['pricePerUnit'] ?? 0).toDouble(),
      pricePerDelivery: (d['pricePerDelivery'] ?? 0).toDouble(),
      description:      d['description'] ?? '',
      isActive:         d['isActive'] ?? true,
      createdAt:        (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:        (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId':         vendorId,
    'name':             name,
    'serviceType':      serviceType,
    'frequency':        frequencyStr,
    'quantity':         quantity,
    'unit':             unit,
    'pricePerUnit':     pricePerUnit,
    'pricePerDelivery': pricePerDelivery,
    'description':      description,
    'isActive':         isActive,
    'createdAt':        Timestamp.fromDate(createdAt),
    'updatedAt':        FieldValue.serverTimestamp(),
  };

  PlanModel copyWith({
    String? name,
    String? serviceType,
    String? frequencyStr,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    double? pricePerDelivery,
    String? description,
    bool? isActive,
  }) =>
      PlanModel(
        id:               id,
        vendorId:         vendorId,
        name:             name ?? this.name,
        serviceType:      serviceType ?? this.serviceType,
        frequencyStr:     frequencyStr ?? this.frequencyStr,
        quantity:         quantity ?? this.quantity,
        unit:             unit ?? this.unit,
        pricePerUnit:     pricePerUnit ?? this.pricePerUnit,
        pricePerDelivery: pricePerDelivery ?? this.pricePerDelivery,
        description:      description ?? this.description,
        isActive:         isActive ?? this.isActive,
        createdAt:        createdAt,
        updatedAt:        DateTime.now(),
      );
}