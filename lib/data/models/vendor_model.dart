// lib/data/models/vendor_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
part 'vendor_model.g.dart';

enum ServiceType { milk, water, newspaper, tiffin, grocery, custom }

@HiveType(typeId: AppConstants.tidVendorModel)
class VendorModel extends HiveObject {
  @HiveField(0)  final String id;
  @HiveField(1)  final String name;
  @HiveField(2)  final String businessName;
  @HiveField(3)  final String email;
  @HiveField(4)  final String phone;
  @HiveField(5)  final String address;
  @HiveField(6)  final String city;
  @HiveField(7)  final String serviceTypeStr;  // stored as string for Hive
  @HiveField(8)  final String? profileImageUrl;
  @HiveField(9)  final String? fcmToken;
  @HiveField(10) final bool isActive;
  @HiveField(11) final DateTime createdAt;
  @HiveField(12) final DateTime updatedAt;
  @HiveField(13) final double totalRevenue;
  @HiveField(14) final int totalCustomers;
  @HiveField(15) final Map<String, dynamic> settings;
  @HiveField(16, defaultValue: []) final List<String> areas;
  @HiveField(17, defaultValue: ['07:00 AM']) final List<String> timeSlots;
  @HiveField(18, defaultValue: 'Basic') final String planName;

   VendorModel({
    required this.id,
    required this.name,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.serviceTypeStr,
    this.profileImageUrl,
    this.fcmToken,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.totalRevenue = 0,
    this.totalCustomers = 0,
    this.settings = const {},
    this.areas = const [],
    this.timeSlots = const ['07:00 AM'],
    this.planName = 'Basic',
  });

  ServiceType get serviceType => ServiceType.values.firstWhere(
        (e) => e.name == serviceTypeStr,
    orElse: () => ServiceType.custom,
  );

  String get serviceEmoji {
    switch (serviceType) {
      case ServiceType.milk:      return '🥛';
      case ServiceType.water:     return '💧';
      case ServiceType.newspaper: return '📰';
      case ServiceType.tiffin:    return '🍱';
      case ServiceType.grocery:   return '🛒';
      case ServiceType.custom:    return '📦';
    }
  }

  factory VendorModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VendorModel(
      id:             doc.id,
      name:           d['name'] ?? '',
      businessName:   d['businessName'] ?? '',
      email:          d['email'] ?? '',
      phone:          d['phone'] ?? '',
      address:        d['address'] ?? '',
      city:           d['city'] ?? '',
      serviceTypeStr: d['serviceType'] ?? 'custom',
      profileImageUrl: d['profileImageUrl'],
      fcmToken:       d['fcmToken'],
      isActive:       d['isActive'] ?? true,
      createdAt:      (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:      (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalRevenue:   (d['totalRevenue'] ?? 0).toDouble(),
      totalCustomers: d['totalCustomers'] ?? 0,
      settings:       Map<String, dynamic>.from(d['settings'] ?? {}),
      areas:          List<String>.from(d['areas'] ?? []),
      timeSlots:      List<String>.from(d['timeSlots'] ?? ['07:00 AM']),
      planName:       d['planName'] ?? 'Basic',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':            name,
    'businessName':    businessName,
    'email':           email,
    'phone':           phone,
    'address':         address,
    'city':            city,
    'serviceType':     serviceTypeStr,
    'profileImageUrl': profileImageUrl,
    'fcmToken':        fcmToken,
    'isActive':        isActive,
    'createdAt':       Timestamp.fromDate(createdAt),
    'updatedAt':       FieldValue.serverTimestamp(),
    'totalRevenue':    totalRevenue,
    'totalCustomers':  totalCustomers,
    'settings':        settings,
    'areas':           areas,
    'timeSlots':       timeSlots,
    'planName':        planName,
  };

  VendorModel copyWith({
    String? name,
    String? businessName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? serviceTypeStr,
    String? profileImageUrl,
    String? fcmToken,
    bool? isActive,
    double? totalRevenue,
    int? totalCustomers,
    Map<String, dynamic>? settings,
    List<String>? areas,
    List<String>? timeSlots,
    String? planName,
  }) => VendorModel(
    id:             id,
    name:           name ?? this.name,
    businessName:   businessName ?? this.businessName,
    email:          email ?? this.email,
    phone:          phone ?? this.phone,
    address:        address ?? this.address,
    city:           city ?? this.city,
    serviceTypeStr: serviceTypeStr ?? this.serviceTypeStr,
    profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    fcmToken:       fcmToken ?? this.fcmToken,
    isActive:       isActive ?? this.isActive,
    createdAt:      createdAt,
    updatedAt:      DateTime.now(),
    totalRevenue:   totalRevenue ?? this.totalRevenue,
    totalCustomers: totalCustomers ?? this.totalCustomers,
    settings:       settings ?? this.settings,
    areas:          areas ?? this.areas,
    timeSlots:      timeSlots ?? this.timeSlots,
    planName:       planName ?? this.planName,
  );
}