// lib/module/auth/register/register_binding.dart
import 'package:get/get.dart';
import 'register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    // AuthService & VendorRepository are registered permanently in main.dart
    Get.lazyPut<RegisterController>(() => RegisterController());
  }
}