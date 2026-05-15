// lib/data/models/delivery_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
part 'delivery_model.g.dart';
enum DeliveryStatus { pending, delivered, missed, cancelled, extra }

@HiveType(typeId: AppConstants.tidDeliveryModel)
class DeliveryModel extends HiveObject {
  @HiveField(0)  final String id;
  @HiveField(1)  final String vendorId;
  @HiveField(2)  final String customerId;
  @HiveField(3)  final String customerName;
  @HiveField(4)  final String customerAddress;
  @HiveField(5)  final String? subscriptionId;
  @HiveField(6)  final String serviceTypeStr;
  @HiveField(7)  final String statusStr;
  @HiveField(8)  final double quantity;
  @HiveField(9)  final String unit;
  @HiveField(10) final double amount;
  @HiveField(11) final DateTime scheduledDate;
  @HiveField(12) final DateTime? deliveredAt;
  @HiveField(13) final String? notes;
  @HiveField(14) final bool isPaid;
  @HiveField(15) final bool isSynced;          // offline sync flag
  @HiveField(16) final DateTime createdAt;
  @HiveField(17) final DateTime updatedAt;
  @HiveField(18) final String? routeId;
  @HiveField(19) final int routeOrder;
  @HiveField(20) final String deliverySlot;
  @HiveField(21) final bool isExtraOrder;

   DeliveryModel({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    required this.customerAddress,
    this.subscriptionId,
    required this.serviceTypeStr,
    this.statusStr = 'pending',
    required this.quantity,
    this.unit = 'unit',
    required this.amount,
    required this.scheduledDate,
    this.deliveredAt,
    this.notes,
    this.isPaid = false,
    this.isSynced = true,
    required this.createdAt,
    required this.updatedAt,
    this.routeId,
    this.routeOrder = 0,
    this.deliverySlot = '07:00 AM',
    this.isExtraOrder = false,
  });

  DeliveryStatus get status => DeliveryStatus.values.firstWhere(
          (e) => e.name == statusStr, orElse: () => DeliveryStatus.pending);

  bool get isPending   => status == DeliveryStatus.pending;
  bool get isDelivered => status == DeliveryStatus.delivered;
  bool get isMissed    => status == DeliveryStatus.missed;
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  int get statusColor {
    switch (status) {
      case DeliveryStatus.pending:   return 0xFFF59E0B;
      case DeliveryStatus.delivered: return 0xFF22C55E;
      case DeliveryStatus.missed:    return 0xFFEF4444;
      case DeliveryStatus.cancelled: return 0xFF9CA3AF;
      case DeliveryStatus.extra:     return 0xFF8B5CF6;
    }
  }

  factory DeliveryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DeliveryModel(
      id:              doc.id,
      vendorId:        d['vendorId'] ?? '',
      customerId:      d['customerId'] ?? '',
      customerName:    d['customerName'] ?? '',
      customerAddress: d['customerAddress'] ?? '',
      subscriptionId:  d['subscriptionId'],
      serviceTypeStr:  d['serviceType'] ?? 'custom',
      statusStr:       d['status'] ?? 'pending',
      quantity:        (d['quantity'] ?? 1).toDouble(),
      unit:            d['unit'] ?? 'unit',
      amount:          (d['amount'] ?? 0).toDouble(),
      scheduledDate:   (d['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt:     (d['deliveredAt'] as Timestamp?)?.toDate(),
      notes:           d['notes'],
      isPaid:          d['isPaid'] ?? false,
      isSynced:        true,
      createdAt:       (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:       (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      routeId:         d['routeId'],
      routeOrder:      d['routeOrder'] ?? 0,
      deliverySlot:    d['deliverySlot'] ?? '07:00 AM',
      isExtraOrder:    d['isExtraOrder'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId':        vendorId,
    'customerId':      customerId,
    'customerName':    customerName,
    'customerAddress': customerAddress,
    'subscriptionId':  subscriptionId,
    'serviceType':     serviceTypeStr,
    'status':          statusStr,
    'quantity':        quantity,
    'unit':            unit,
    'amount':          amount,
    'scheduledDate':   Timestamp.fromDate(scheduledDate),
    'deliveredAt':     deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    'notes':           notes,
    'isPaid':          isPaid,
    'createdAt':       Timestamp.fromDate(createdAt),
    'updatedAt':       FieldValue.serverTimestamp(),
    'routeId':         routeId,
    'routeOrder':      routeOrder,
    'deliverySlot':    deliverySlot,
    'isExtraOrder':    isExtraOrder,
  };

  DeliveryModel copyWith({
    String? statusStr,
    DateTime? deliveredAt,
    String? notes,
    bool? isPaid,
    bool? isSynced,
  }) => DeliveryModel(
    id: id, vendorId: vendorId, customerId: customerId,
    customerName: customerName, customerAddress: customerAddress,
    subscriptionId: subscriptionId, serviceTypeStr: serviceTypeStr,
    statusStr:   statusStr ?? this.statusStr,
    quantity: quantity, unit: unit, amount: amount,
    scheduledDate: scheduledDate,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    notes:  notes ?? this.notes,
    isPaid: isPaid ?? this.isPaid,
    isSynced: isSynced ?? this.isSynced,
    createdAt: createdAt, updatedAt: DateTime.now(),
    routeId: routeId, routeOrder: routeOrder,
    deliverySlot: deliverySlot, isExtraOrder: isExtraOrder,
  );
}