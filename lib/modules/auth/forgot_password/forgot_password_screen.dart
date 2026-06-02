// lib/modules/auth/forgot_password/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../widgets/inputs/app_text_field.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Obx(() {
          if (controller.isEmailSent.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_outlined,
                        size: 40, color: AppColors.success),
                  ),
                  const SizedBox(height: 20),
                  const Text('Check Your Email',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins')),
                  const SizedBox(height: 10),
                  Text(
                    'Password reset link sent to\n${controller.emailCtrl.text}',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary,
                        fontFamily: 'Poppins', height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(label: 'Back to Login', onTap: Get.back),
                ],
              ),
            );
          }

          return Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Forgot Password?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary, fontFamily: 'Poppins')),
                const SizedBox(height: 8),
                const Text('Enter your registered email and we\'ll send you a reset link.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary,
                        fontFamily: 'Poppins', height: 1.5)),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Email Address', hint: 'vendor@example.com',
                  controller: controller.emailCtrl,
                  validator: controller.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  prefix: const Icon(Icons.email_outlined, size: 18, color: AppColors.textHint),
                ),
                Obx(() => controller.errorMessage.isNotEmpty
                    ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(controller.errorMessage.value,
                      style: const TextStyle(fontSize: 12, color: AppColors.error,
                          fontFamily: 'Poppins')),
                )
                    : const SizedBox()),
                const SizedBox(height: 24),
                Obx(() => PrimaryButton(
                  label: 'Send Reset Link',
                  onTap: controller.sendResetEmail,
                  isLoading: controller.isLoading.value,
                )),
              ],
            ),
          );
        }),
      ),
    );
  }
}
