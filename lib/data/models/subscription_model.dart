// lib/data/models/subscription_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
part 'subscription_model.g.dart';
enum SubscriptionFrequency { daily, alternateDay, weekdays, weekends, weekly, custom }
enum SubscriptionStatus    { active, paused, cancelled, expired }

@HiveType(typeId: AppConstants.tidSubscriptionModel)
class SubscriptionModel extends HiveObject {
  @HiveField(0)  final String id;
  @HiveField(1)  final String vendorId;
  @HiveField(2)  final String customerId;
  @HiveField(3)  final String customerName;
  @HiveField(4)  final String serviceTypeStr;
  @HiveField(5)  final String frequencyStr;
  @HiveField(6)  final String statusStr;
  @HiveField(7)  final double quantity;          // e.g. 1.5 (litres/units)
  @HiveField(8)  final String unit;              // 'litre', 'packet', 'copy', 'box'
  @HiveField(9)  final double pricePerUnit;
  @HiveField(10) final double pricePerDelivery;  // quantity × pricePerUnit
  @HiveField(11) final String deliverySlot;      // '06:00 AM - 07:00 AM'
  @HiveField(12) final DateTime startDate;
  @HiveField(13) final DateTime? endDate;
  @HiveField(14) final DateTime? pausedUntil;
  @HiveField(15) final DateTime? nextDeliveryDate;
  @HiveField(16) final List<int> customDays;    // 0=Mon..6=Sun for custom freq
  @HiveField(17) final int completedDeliveries;
  @HiveField(18) final int pendingDeliveries;
  @HiveField(19) final String? notes;
  @HiveField(20) final DateTime createdAt;
  @HiveField(21) final DateTime updatedAt;

   SubscriptionModel({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    required this.serviceTypeStr,
    this.frequencyStr = 'daily',
    this.statusStr = 'active',
    required this.quantity,
    this.unit = 'unit',
    required this.pricePerUnit,
    required this.pricePerDelivery,
    this.deliverySlot = '07:00 AM',
    required this.startDate,
    this.endDate,
    this.pausedUntil,
    this.nextDeliveryDate,
    this.customDays = const [],
    this.completedDeliveries = 0,
    this.pendingDeliveries = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  SubscriptionFrequency get frequency => SubscriptionFrequency.values.firstWhere(
          (e) => e.name == frequencyStr, orElse: () => SubscriptionFrequency.daily);

  SubscriptionStatus get status => SubscriptionStatus.values.firstWhere(
          (e) => e.name == statusStr, orElse: () => SubscriptionStatus.active);

  bool get isActive => status == SubscriptionStatus.active;
  bool get isPaused => status == SubscriptionStatus.paused;

  double get estimatedMonthlyRevenue {
    switch (frequency) {
      case SubscriptionFrequency.daily:       return pricePerDelivery * 30;
      case SubscriptionFrequency.alternateDay: return pricePerDelivery * 15;
      case SubscriptionFrequency.weekdays:    return pricePerDelivery * 22;
      case SubscriptionFrequency.weekends:    return pricePerDelivery * 8;
      case SubscriptionFrequency.weekly:      return pricePerDelivery * 4;
      case SubscriptionFrequency.custom:      return pricePerDelivery * customDays.length * 4;
    }
  }

  String get frequencyLabel {
    switch (frequency) {
      case SubscriptionFrequency.daily:        return 'Daily';
      case SubscriptionFrequency.alternateDay: return 'Alternate Day';
      case SubscriptionFrequency.weekdays:     return 'Weekdays';
      case SubscriptionFrequency.weekends:     return 'Weekends';
      case SubscriptionFrequency.weekly:       return 'Weekly';
      case SubscriptionFrequency.custom:       return 'Custom';
    }
  }

  /// Returns whether a delivery should happen on [date] based on frequency
  bool shouldDeliverOn(DateTime date) {
    switch (frequency) {
      case SubscriptionFrequency.daily:
        return true;
      case SubscriptionFrequency.alternateDay:
        final diff = date.difference(startDate).inDays;
        return diff % 2 == 0;
      case SubscriptionFrequency.weekdays:
        return date.weekday <= 5; // Mon–Fri
      case SubscriptionFrequency.weekends:
        return date.weekday >= 6; // Sat–Sun
      case SubscriptionFrequency.weekly:
        return date.weekday == startDate.weekday;
      case SubscriptionFrequency.custom:
        return customDays.contains(date.weekday - 1); // 0=Mon
    }
  }

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      id:                   doc.id,
      vendorId:             d['vendorId'] ?? '',
      customerId:           d['customerId'] ?? '',
      customerName:         d['customerName'] ?? '',
      serviceTypeStr:       d['serviceType'] ?? 'custom',
      frequencyStr:         d['frequency'] ?? 'daily',
      statusStr:            d['status'] ?? 'active',
      quantity:             (d['quantity'] ?? 1).toDouble(),
      unit:                 d['unit'] ?? 'unit',
      pricePerUnit:         (d['pricePerUnit'] ?? 0).toDouble(),
      pricePerDelivery:     (d['pricePerDelivery'] ?? 0).toDouble(),
      deliverySlot:         d['deliverySlot'] ?? '07:00 AM',
      startDate:            (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate:              (d['endDate'] as Timestamp?)?.toDate(),
      pausedUntil:          (d['pausedUntil'] as Timestamp?)?.toDate(),
      nextDeliveryDate:     (d['nextDeliveryDate'] as Timestamp?)?.toDate(),
      customDays:           List<int>.from(d['customDays'] ?? []),
      completedDeliveries:  d['completedDeliveries'] ?? 0,
      pendingDeliveries:    d['pendingDeliveries'] ?? 0,
      notes:                d['notes'],
      createdAt:            (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:            (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId':            vendorId,
    'customerId':          customerId,
    'customerName':        customerName,
    'serviceType':         serviceTypeStr,
    'frequency':           frequencyStr,
    'status':              statusStr,
    'quantity':            quantity,
    'unit':                unit,
    'pricePerUnit':        pricePerUnit,
    'pricePerDelivery':    pricePerDelivery,
    'deliverySlot':        deliverySlot,
    'startDate':           Timestamp.fromDate(startDate),
    'endDate':             endDate != null ? Timestamp.fromDate(endDate!) : null,
    'pausedUntil':         pausedUntil != null ? Timestamp.fromDate(pausedUntil!) : null,
    'nextDeliveryDate':    nextDeliveryDate != null ? Timestamp.fromDate(nextDeliveryDate!) : null,
    'customDays':          customDays,
    'completedDeliveries': completedDeliveries,
    'pendingDeliveries':   pendingDeliveries,
    'notes':               notes,
    'createdAt':           Timestamp.fromDate(createdAt),
    'updatedAt':           FieldValue.serverTimestamp(),
  };

  SubscriptionModel copyWith({
    String? statusStr,
    DateTime? pausedUntil,
    DateTime? nextDeliveryDate,
    double? quantity,
    double? pricePerUnit,
    double? pricePerDelivery,
    int? completedDeliveries,
    int? pendingDeliveries,
  }) => SubscriptionModel(
    id: id, vendorId: vendorId, customerId: customerId,
    customerName: customerName, serviceTypeStr: serviceTypeStr,
    frequencyStr: frequencyStr,
    statusStr:          statusStr ?? this.statusStr,
    quantity:           quantity ?? this.quantity,
    unit: unit,
    pricePerUnit:       pricePerUnit ?? this.pricePerUnit,
    pricePerDelivery:   pricePerDelivery ?? this.pricePerDelivery,
    deliverySlot: deliverySlot, startDate: startDate, endDate: endDate,
    pausedUntil:        pausedUntil ?? this.pausedUntil,
    nextDeliveryDate:   nextDeliveryDate ?? this.nextDeliveryDate,
    customDays: customDays,
    completedDeliveries: completedDeliveries ?? this.completedDeliveries,
    pendingDeliveries:  pendingDeliveries ?? this.pendingDeliveries,
    notes: notes, createdAt: createdAt, updatedAt: DateTime.now(),
  );
}