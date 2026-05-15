// lib/modules/auth/login/login_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/extensions.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../data/repositories/vendor_repository.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/notification_service.dart';

class LoginController extends GetxController {
  final AuthService _auth     = Get.find<AuthService>();
  final VendorRepository _repo = Get.find<VendorRepository>();

  final formKey = GlobalKey<FormState>();
  final emailCtrl    = TextEditingController();
  final passwordCtrl = TextEditingController();

  final isLoading     = false.obs;
  final showPassword  = false.obs;
  final errorMessage  = ''.obs;

  void togglePasswordVisibility() => showPassword.toggle();

  String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!v.isValidEmail) return 'Enter a valid email';
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    errorMessage.value = '';
    isLoading.value = true;

    final result = await _auth.login(emailCtrl.text, passwordCtrl.text);

    await result.fold(
          (failure) async {
        errorMessage.value = failure.message;
        isLoading.value = false;
      },
          (credential) async {
        final uid = credential.user!.uid;
        final vendorResult = await _repo.fetchVendor(uid);

        vendorResult.fold(
              (failure) {
            errorMessage.value = 'Account setup incomplete. Contact support.';
            isLoading.value = false;
          },
              (vendor) async {
            await LocalStorageService.setVendorId(uid);
            final token = await Get.find<NotificationService>().getToken();
            if (token != null) await _repo.updateFcmToken(uid, token);
            isLoading.value = false;
            Get.offAllNamed(Routes.dashboard);
          },
        );
      },
    );
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}