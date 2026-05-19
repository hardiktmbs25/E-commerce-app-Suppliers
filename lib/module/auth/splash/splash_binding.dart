// lib/module/auth/splash/splash_binding.dart
import 'package:get/get.dart';
import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // AuthService & VendorRepository are registered permanently in main.dart
    Get.put(SplashController());
  }
}