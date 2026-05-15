// lib/modules/auth/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../widgets/inputs/app_text_field.dart';
import 'login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Header
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('VT',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                            color: Colors.white, fontFamily: 'Poppins')),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Welcome back 👋',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary, fontFamily: 'Poppins')),
                const SizedBox(height: 8),
                const Text('Login to manage your deliveries and customers.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary,
                        fontFamily: 'Poppins', height: 1.5)),
                const SizedBox(height: 40),
                // Email
                AppTextField(
                  label: 'Email Address',
                  hint: 'vendor@example.com',
                  controller: controller.emailCtrl,
                  validator: controller.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefix: const Icon(Icons.email_outlined, size: 18,
                      color: AppColors.textHint),
                ),
                const SizedBox(height: 16),
                // Password
                Obx(() => AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: controller.passwordCtrl,
                  validator: controller.validatePassword,
                  obscureText: !controller.showPassword.value,
                  textInputAction: TextInputAction.done,
                  prefix: const Icon(Icons.lock_outline_rounded, size: 18,
                      color: AppColors.textHint),
                  suffix: IconButton(
                    icon: Icon(
                      controller.showPassword.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18, color: AppColors.textHint,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                )),
                const SizedBox(height: 12),
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Get.toNamed(Routes.forgotPassword),
                    child: const Text('Forgot Password?',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.primary, fontFamily: 'Poppins')),
                  ),
                ),
                const SizedBox(height: 8),
                // Error message
                Obx(() => controller.errorMessage.isNotEmpty
                    ? Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(controller.errorMessage.value,
                          style: const TextStyle(fontSize: 12, color: AppColors.error,
                              fontFamily: 'Poppins'))),
                    ],
                  ),
                )
                    : const SizedBox()),
                const SizedBox(height: 8),
                // Login button
                Obx(() => PrimaryButton(
                  label: 'Login',
                  onTap: controller.login,
                  isLoading: controller.isLoading.value,
                )),
                const SizedBox(height: 20),
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ",
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary,
                            fontFamily: 'Poppins')),
                    GestureDetector(
                      onTap: () => Get.toNamed(Routes.register),
                      child: const Text('Register',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppColors.primary, fontFamily: 'Poppins')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}