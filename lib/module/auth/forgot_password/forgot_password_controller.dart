// lib/modules/auth/forgot_password/forgot_password_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/extensions.dart';
import '../../../services/auth_service.dart';

class ForgotPasswordController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final formKey  = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final isLoading = false.obs;
  final isEmailSent = false.obs;
  final errorMessage = ''.obs;

  String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!v.isValidEmail) return 'Enter a valid email';
    return null;
  }

  Future<void> sendResetEmail() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    errorMessage.value = '';
    final result = await _auth.sendPasswordResetEmail(emailCtrl.text);
    result.fold(
          (f) { errorMessage.value = f.message; isLoading.value = false; },
          (_) { isEmailSent.value = true; isLoading.value = false; },
    );
  }

  @override
  void onClose() { emailCtrl.dispose(); super.onClose(); }
}