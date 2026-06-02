import 'package:get/get.dart';
import '../../data/models/staff_model.dart';
import '../../data/repositories/staff_repository.dart';
import '../../services/auth_service.dart';

class StaffController extends GetxController {
  final StaffRepository _staffRepo = Get.find();

  final RxList<StaffModel> staffList = <StaffModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    staffList.bindStream(_staffRepo.watchStaff());
  }

  Future<void> addStaffMember({
    required String name,
    required String phone,
    required StaffRole role,
    required double salary,
  }) async {
    try {
      isLoading.value = true;
      final newStaff = StaffModel(
        id: '',
        vendorId: AuthService.to.vendorId,
        name: name,
        phone: phone,
        roleStr: role.name,
        salary: salary,
        joinedAt: DateTime.now(),
      );
      await _staffRepo.addStaff(newStaff);
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add staff: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateStaffStatus(StaffModel staff, StaffStatus status) async {
    try {
      final updated = StaffModel(
        id: staff.id,
        vendorId: staff.vendorId,
        name: staff.name,
        phone: staff.phone,
        roleStr: staff.roleStr,
        statusStr: status.name,
        salary: staff.salary,
        joinedAt: staff.joinedAt,
        profileImageUrl: staff.profileImageUrl,
        permissions: staff.permissions,
      );
      await _staffRepo.updateStaff(updated);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status: $e');
    }
  }
}