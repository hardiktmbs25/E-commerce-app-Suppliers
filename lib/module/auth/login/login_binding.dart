// lib/modules/auth/login/login_binding.dart
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../data/repositories/vendor_repository.dart';
import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<VendorRepository>(() => VendorRepository(), fenix: true);
    Get.lazyPut<LoginController>(() => LoginController());
  }
}