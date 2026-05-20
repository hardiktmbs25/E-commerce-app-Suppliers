// lib/data/models/time_slot_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// A time slot available for home delivery.
/// Stored at: vendors/{vendorId}/timeSlots/{slotId}
class TimeSlotModel {
  final String id;
  final String vendorId;
  final String label;      // e.g. "6:00 AM - 7:00 AM"
  final String startTime;  // "06:00"
  final String endTime;    // "07:00"
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  const TimeSlotModel({
    required this.id,
    required this.vendorId,
    required this.label,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory TimeSlotModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TimeSlotModel(
      id:         doc.id,
      vendorId:   d['vendorId'] ?? '',
      label:      d['label'] ?? '',
      startTime:  d['startTime'] ?? '',
      endTime:    d['endTime'] ?? '',
      isActive:   d['isActive'] ?? true,
      sortOrder:  d['sortOrder'] ?? 0,
      createdAt:  (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId':  vendorId,
    'label':     label,
    'startTime': startTime,
    'endTime':   endTime,
    'isActive':  isActive,
    'sortOrder': sortOrder,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}