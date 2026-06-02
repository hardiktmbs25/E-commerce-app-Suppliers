import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'staff_model.g.dart';

enum StaffRole { owner, manager, deliveryBoy, helper }
enum StaffStatus { active, inactive, onLeave }

@HiveType(typeId: AppConstants.tidStaffModel)
class StaffModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String vendorId;
  @HiveField(2) final String name;
  @HiveField(3) final String phone;
  @HiveField(4) final String roleStr;
  @HiveField(5) final String statusStr;
  @HiveField(6) final double salary;
  @HiveField(7) final DateTime joinedAt;
  @HiveField(8) final String? profileImageUrl;
  @HiveField(9) final String? fcmToken;
  @HiveField(10) final Map<String, dynamic> permissions;

  StaffModel({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.phone,
    this.roleStr = 'deliveryBoy',
    this.statusStr = 'active',
    this.salary = 0,
    required this.joinedAt,
    this.profileImageUrl,
    this.fcmToken,
    this.permissions = const {},
  });

  StaffRole get role => StaffRole.values.firstWhere(
    (e) => e.name == roleStr,
    orElse: () => StaffRole.deliveryBoy,
  );

  StaffStatus get status => StaffStatus.values.firstWhere(
    (e) => e.name == statusStr,
    orElse: () => StaffStatus.active,
  );

  factory StaffModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StaffModel(
      id: doc.id,
      vendorId: d['vendorId'] ?? '',
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      roleStr: d['role'] ?? 'deliveryBoy',
      statusStr: d['status'] ?? 'active',
      salary: (d['salary'] ?? 0).toDouble(),
      joinedAt: (d['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImageUrl: d['profileImageUrl'],
      fcmToken: d['fcmToken'],
      permissions: Map<String, dynamic>.from(d['permissions'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vendorId': vendorId,
    'name': name,
    'phone': phone,
    'role': roleStr,
    'status': statusStr,
    'salary': salary,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'profileImageUrl': profileImageUrl,
    'fcmToken': fcmToken,
    'permissions': permissions,
  };
}