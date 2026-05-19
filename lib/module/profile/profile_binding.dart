// lib/module/profile/profile_binding.dart
import 'package:get/get.dart';
import 'profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // AuthService & VendorRepository are registered permanently in main.dart
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}