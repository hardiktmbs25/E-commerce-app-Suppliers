// lib/data/models/time_slot_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'time_slot_model.g.dart';

/// A time slot available for home delivery.
/// Stored at: vendors/{vendorId}/timeSlots/{slotId}
@HiveType(typeId: AppConstants.tidTimeSlotModel)
class TimeSlotModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String vendorId;
  @HiveField(2) final String label;      // e.g. "6:00 AM - 7:00 AM"
  @HiveField(3) final String startTime;  // "06:00"
  @HiveField(4) final String endTime;    // "07:00"
  @HiveField(5) final bool isActive;
  @HiveField(6) final int sortOrder;
  @HiveField(7) final DateTime createdAt;

  TimeSlotModel({
    required this.id,
    required this.vendorId,
    required this.label,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  DateTime getStartDateTime([DateTime? baseDate]) {
    return _parseTimeToDateTime(startTime, baseDate);
  }

  DateTime getEndDateTime([DateTime? baseDate]) {
    return _parseTimeToDateTime(endTime, baseDate);
  }

  DateTime _parseTimeToDateTime(String timeStr, DateTime? baseDate) {
    final now = baseDate ?? DateTime.now();
    // Expected format: "HH:mm" or "hh:mm AM"
    final cleaned = timeStr.trim().toUpperCase();
    
    int hour = 0;
    int minute = 0;

    if (cleaned.contains('AM') || cleaned.contains('PM')) {
      final parts = cleaned.split(' ');
      final timeParts = parts[0].split(':');
      hour = int.tryParse(timeParts[0]) ?? 0;
      minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
      
      final meridian = parts[1];
      if (meridian == 'PM' && hour != 12) hour += 12;
      if (meridian == 'AM' && hour == 12) hour = 0;
    } else {
      final parts = cleaned.split(':');
      hour = int.tryParse(parts[0]) ?? 0;
      minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    }

    return DateTime(now.year, now.month, now.day, hour, minute);
  }



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