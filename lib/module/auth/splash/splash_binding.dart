// lib/modules/auth/splash/splash_binding.dart
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../data/repositories/vendor_repository.dart';
import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthService(), permanent: true);
    Get.put(VendorRepository(), permanent: true);
    Get.put(SplashController());
    // Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    // Get.lazyPut<VendorRepository>(() => VendorRepository(), fenix: true);
    // Get.lazyPut<SplashController>(() => SplashController());
  }
}