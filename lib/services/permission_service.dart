import 'package:get/get.dart';
import '../data/models/staff_model.dart';
import 'auth_service.dart';

class PermissionService extends GetxService {
  static PermissionService get to => Get.find();

  // Observable current staff member if logged in as staff
  final Rxn<StaffModel> currentStaff = Rxn<StaffModel>();

  bool get isOwner => AuthService.to.isLoggedIn && currentStaff.value == null;
  bool get isManager => currentStaff.value?.role == StaffRole.manager;
  bool get isDeliveryBoy => currentStaff.value?.role == StaffRole.deliveryBoy;

  bool canManageStaff() => isOwner || isManager;
  bool canManageRoutes() => isOwner || isManager;
  bool canViewAnalytics() => isOwner || isManager;
  bool canCollectPayments() => true; // Everyone can collect payments
  bool canDeleteData() => isOwner;

  // Initialize if needed
  Future<PermissionService> init() async {
    return this;
  }
}