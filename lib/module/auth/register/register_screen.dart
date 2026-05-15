// lib/modules/auth/register/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../widgets/inputs/app_text_field.dart';
import 'register_controller.dart';

class RegisterScreen extends GetView<RegisterController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tell us about yourself',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary, fontFamily: 'Poppins')),
              const SizedBox(height: 6),
              const Text('Fill in your details to get started.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 28),

              // Personal Info
              AppTextField(label: 'Full Name', hint: 'Ramesh Kumar',
                  controller: controller.nameCtrl,
                  validator: (v) => controller.validateRequired(v, 'Name'),
                  prefix: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textHint)),
              const SizedBox(height: 16),
              AppTextField(label: 'Business Name', hint: 'Ramesh Milk Dairy',
                  controller: controller.businessCtrl,
                  validator: (v) => controller.validateRequired(v, 'Business name'),
                  prefix: const Icon(Icons.storefront_outlined, size: 18, color: AppColors.textHint)),
              const SizedBox(height: 16),
              AppTextField(label: 'Mobile Number', hint: '9876543210',
                  controller: controller.phoneCtrl,
                  validator: controller.validatePhone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  prefix: const Icon(Icons.phone_outlined, size: 18, color: AppColors.textHint)),
              const SizedBox(height: 16),
              AppTextField(label: 'Email Address', hint: 'ramesh@example.com',
                  controller: controller.emailCtrl,
                  validator: controller.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  prefix: const Icon(Icons.email_outlined, size: 18, color: AppColors.textHint)),
              const SizedBox(height: 16),
              AppTextField(label: 'City', hint: 'Mumbai',
                  controller: controller.cityCtrl,
                  validator: (v) => controller.validateRequired(v, 'City'),
                  prefix: const Icon(Icons.location_city_outlined, size: 18, color: AppColors.textHint)),
              const SizedBox(height: 16),
              AppTextField(label: 'Business Address', hint: '123, Main Road, Andheri West',
                  controller: controller.addressCtrl,
                  validator: (v) => controller.validateRequired(v, 'Address'),
                  maxLines: 2,
                  prefix: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textHint)),
              const SizedBox(height: 16),

              // Service type
              const Text('Service Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary, fontFamily: 'Poppins')),
              const SizedBox(height: 8),
              Obx(() => Wrap(
                spacing: 8, runSpacing: 8,
                children: controller.serviceOptions.map((opt) {
                  final isSelected = controller.selectedService.value == opt['value'];
                  return GestureDetector(
                    onTap: () => controller.setService(opt['value']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(opt['label']!,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontFamily: 'Poppins',
                          )),
                    ),
                  );
                }).toList(),
              )),
              const SizedBox(height: 16),

              // Password
              Obx(() => AppTextField(
                label: 'Password', hint: '••••••••',
                controller: controller.passwordCtrl,
                validator: controller.validatePassword,
                obscureText: !controller.showPassword.value,
                prefix: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textHint),
                suffix: IconButton(
                  icon: Icon(controller.showPassword.value
                      ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18, color: AppColors.textHint),
                  onPressed: controller.togglePassword,
                ),
              )),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Confirm Password', hint: '••••••••',
                controller: controller.confirmPassCtrl,
                validator: controller.validateConfirmPassword,
                obscureText: true,
                textInputAction: TextInputAction.done,
                prefix: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textHint),
              ),

              // Error
              Obx(() => controller.errorMessage.isNotEmpty
                  ? Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(controller.errorMessage.value,
                    style: const TextStyle(fontSize: 12, color: AppColors.error,
                        fontFamily: 'Poppins')),
              )
                  : const SizedBox()),
              const SizedBox(height: 24),

              Obx(() => PrimaryButton(
                label: 'Create Account',
                onTap: controller.register,
                isLoading: controller.isLoading.value,
              )),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary,
                          fontFamily: 'Poppins')),
                  GestureDetector(
                    onTap: Get.back,
                    child: const Text('Login',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppColors.primary, fontFamily: 'Poppins')),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}