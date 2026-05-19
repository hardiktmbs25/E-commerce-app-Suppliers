// lib/module/auth/login/login_binding.dart
import 'package:get/get.dart';
import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // AuthService & VendorRepository are registered permanently in main.dart
    Get.lazyPut<LoginController>(() => LoginController());
  }
}