// lib/modules/auth/register/register_binding.dart
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../data/repositories/vendor_repository.dart';
import 'register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<VendorRepository>(() => VendorRepository(), fenix: true);
    Get.lazyPut<RegisterController>(() => RegisterController());
  }
}