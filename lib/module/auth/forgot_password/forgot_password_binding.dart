// lib/modules/auth/forgot_password/forgot_password_binding.dart
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController());
  }
}