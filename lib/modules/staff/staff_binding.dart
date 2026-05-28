import 'package:get/get.dart';
import '../../data/repositories/staff_repository.dart';
import 'staff_controller.dart';

class StaffBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StaffRepository>(() => StaffRepository());
    Get.lazyPut<StaffController>(() => StaffController());
  }
}