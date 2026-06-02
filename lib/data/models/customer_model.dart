// lib/data/models/customer_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
part 'customer_model.g.dart';

enum CustomerStatus { active, inactive, paused }
enum PaymentStatus { paid, pending, overdue }

@HiveType(typeId: AppConstants.tidCustomerModel)
class CustomerModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String vendorId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final String phone;
  @HiveField(4)
  final String? alternatePhone;
  @HiveField(5)
  final String address;
  @HiveField(6)
  final String? landmark;
  @HiveField(7)
  final String? routeId;
  @HiveField(8)
  final String? routeName;
  @HiveField(9)
  final String serviceTypeStr;
  @HiveField(10)
  final String statusStr;
  @HiveField(11)
  final String paymentStatusStr;
  @HiveField(12, defaultValue: 0.0)
  final double pendingAmount;
  @HiveField(13, defaultValue: 0.0)
  final double totalPaid;
  @HiveField(14)
  final String? notes;
  @HiveField(15)
  final DateTime createdAt;
  @HiveField(16)
  final DateTime updatedAt;
  @HiveField(17, defaultValue: 0)
  final int deliveryOrder; // sequence in route
  @HiveField(18)
  final String? profileImageUrl;
  @HiveField(19, defaultValue: {})
  final Map<String, dynamic> metadata;
  @HiveField(20, defaultValue: [])
  final List<String> activeSubscriptionIds;
  @HiveField(21, defaultValue: 'monthly')
  final String billingType; // 'daily', 'weekly', 'monthly'
  @HiveField(22, defaultValue: 0.0)
  final double walletBalance;
  @HiveField(23)
  final DateTime? pauseStartDate;
  @HiveField(24)
  final DateTime? pauseEndDate;
  @HiveField(25, defaultValue: 0.0)
  final double creditLimit;
  @HiveField(26)
  final DateTime? lastResumeDate;

  CustomerModel({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.phone,
    this.alternatePhone,
    required this.address,
    this.landmark,
    this.routeId,
    this.routeName,
    required this.serviceTypeStr,
    this.statusStr = 'active',
    this.paymentStatusStr = 'pending',
    this.pendingAmount = 0,
    this.totalPaid = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deliveryOrder = 0,
    this.profileImageUrl,
    this.metadata = const {},
    this.activeSubscriptionIds = const [],
    this.billingType = 'monthly',
    this.walletBalance = 0,
    this.pauseStartDate,
    this.pauseEndDate,
    this.creditLimit = 0,
    this.lastResumeDate,
  });

  CustomerStatus get status => CustomerStatus.values.firstWhere(
    (e) => e.name == statusStr,
    orElse: () => CustomerStatus.active,
  );

  PaymentStatus get paymentStatus => PaymentStatus.values.firstWhere(
    (e) => e.name == paymentStatusStr,
    orElse: () => PaymentStatus.pending,
  );

  bool get isActive => status == CustomerStatus.active;

  bool get isPaused => status == CustomerStatus.paused;

  bool get hasPendingAmount => pendingAmount > 0;

  bool isDeliveryPaused(DateTime date) {
    if (status != CustomerStatus.paused) return false;
    if (pauseStartDate == null) return true;
    if (pauseEndDate == null) {
      return date.isAfter(pauseStartDate!) ||
          date.isAtSameMomentAs(pauseStartDate!);
    }
    return (date.isAfter(pauseStartDate!) ||
            date.isAtSameMomentAs(pauseStartDate!)) &&
        (date.isBefore(pauseEndDate!) || date.isAtSameMomentAs(pauseEndDate!));
  }

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      id: doc.id,
      vendorId: d['vendorId'] ?? '',
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      alternatePhone: d['alternatePhone'],
      address: d['address'] ?? '',
      landmark: d['landmark'],
      routeId: d['routeId'],
      routeName: d['routeName'],
      serviceTypeStr: d['serviceType'] ?? 'custom',
      statusStr: d['status'] ?? 'active',
      paymentStatusStr: d['paymentStatus'] ?? 'pending',
      pendingAmount: (d['pendingAmount'] ?? 0).toDouble(),
      totalPaid: (d['totalPaid'] ?? 0).toDouble(),
      notes: d['notes'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveryOrder: d['deliveryOrder'] ?? 0,
      profileImageUrl: d['profileImageUrl'],
      metadata: Map<String, dynamic>.from(d['metadata'] ?? {}),
      activeSubscriptionIds: List<String>.from(
        d['activeSubscriptionIds'] ?? [],
      ),
      billingType: d['billingType'] ?? 'monthly',
      walletBalance: (d['walletBalance'] ?? 0.0).toDouble(),
      pauseStartDate: (d['pauseStartDate'] as Timestamp?)?.toDate(),
      pauseEndDate: (d['pauseEndDate'] as Timestamp?)?.toDate(),
      creditLimit: (d['creditLimit'] ?? 0.0).toDouble(),
      lastResumeDate: (d['lastResumeDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId': vendorId,
    'name': name,
    'phone': phone,
    'alternatePhone': alternatePhone,
    'address': address,
    'landmark': landmark,
    'routeId': routeId,
    'routeName': routeName,
    'serviceType': serviceTypeStr,
    'status': statusStr,
    'paymentStatus': paymentStatusStr,
    'pendingAmount': pendingAmount,
    'totalPaid': totalPaid,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
    'deliveryOrder': deliveryOrder,
    'profileImageUrl': profileImageUrl,
    'metadata': metadata,
    'activeSubscriptionIds': activeSubscriptionIds,
    'billingType': billingType,
    'walletBalance': walletBalance,
    'pauseStartDate': pauseStartDate != null
        ? Timestamp.fromDate(pauseStartDate!)
        : null,
    'pauseEndDate': pauseEndDate != null
        ? Timestamp.fromDate(pauseEndDate!)
        : null,
    'creditLimit': creditLimit,
    'lastResumeDate': lastResumeDate != null
        ? Timestamp.fromDate(lastResumeDate!)
        : null,
  };

  CustomerModel copyWith({
    String? name,
    String? phone,
    String? alternatePhone,
    String? address,
    String? landmark,
    String? routeId,
    String? routeName,
    String? statusStr,
    String? paymentStatusStr,
    double? pendingAmount,
    double? totalPaid,
    String? notes,
    int? deliveryOrder,
    String? profileImageUrl,
    Map<String, dynamic>? metadata,
    List<String>? activeSubscriptionIds,
    String? billingType,
    double? walletBalance,
    DateTime? pauseStartDate,
    DateTime? pauseEndDate,
    double? creditLimit,
    DateTime? lastResumeDate,
  }) => CustomerModel(
    id: id,
    vendorId: vendorId,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    alternatePhone: alternatePhone ?? this.alternatePhone,
    address: address ?? this.address,
    landmark: landmark ?? this.landmark,
    routeId: routeId ?? this.routeId,
    routeName: routeName ?? this.routeName,
    serviceTypeStr: serviceTypeStr,
    statusStr: statusStr ?? this.statusStr,
    paymentStatusStr: paymentStatusStr ?? this.paymentStatusStr,
    pendingAmount: pendingAmount ?? this.pendingAmount,
    totalPaid: totalPaid ?? this.totalPaid,
    notes: notes ?? this.notes,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    deliveryOrder: deliveryOrder ?? this.deliveryOrder,
    profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    metadata: metadata ?? this.metadata,
    activeSubscriptionIds: activeSubscriptionIds ?? this.activeSubscriptionIds,
    billingType: billingType ?? this.billingType,
    walletBalance: walletBalance ?? this.walletBalance,
    pauseStartDate: pauseStartDate ?? this.pauseStartDate,
    pauseEndDate: pauseEndDate ?? this.pauseEndDate,
    creditLimit: creditLimit ?? this.creditLimit,
    lastResumeDate: lastResumeDate ?? this.lastResumeDate,
  );
}
