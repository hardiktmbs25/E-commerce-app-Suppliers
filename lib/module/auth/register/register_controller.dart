// lib/modules/auth/register/register_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/extensions.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../data/repositories/vendor_repository.dart';
import '../../../services/local_storage_service.dart';
import '../../../data/models/vendor_model.dart';

class RegisterController extends GetxController {
  final AuthService _auth     = Get.find<AuthService>();
  final VendorRepository _repo = Get.find<VendorRepository>();

  final formKey    = GlobalKey<FormState>();
  final nameCtrl        = TextEditingController();
  final businessCtrl    = TextEditingController();
  final emailCtrl       = TextEditingController();
  final phoneCtrl       = TextEditingController();
  final addressCtrl     = TextEditingController();
  final cityCtrl        = TextEditingController();
  final passwordCtrl    = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  final selectedService = 'milk'.obs;
  final isLoading       = false.obs;
  final showPassword    = false.obs;
  final errorMessage    = ''.obs;
  final currentStep     = 0.obs; // 0 = personal, 1 = business, 2 = security

  final serviceOptions = [
    {'value': 'milk',      'label': '🥛 Milk Supply'},
    {'value': 'water',     'label': '💧 Water Supply'},
    {'value': 'newspaper', 'label': '📰 Newspaper'},
    {'value': 'tiffin',    'label': '🍱 Tiffin Service'},
    {'value': 'grocery',   'label': '🛒 Grocery'},
    {'value': 'custom',    'label': '📦 Other'},
  ];

  void togglePassword() => showPassword.toggle();
  void setService(String value) => selectedService.value = value;
  void nextStep() { if (currentStep.value < 2) currentStep.value++; }
  void prevStep() { if (currentStep.value > 0) currentStep.value--; }

  String? validateRequired(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!v.isValidEmail) return 'Enter a valid email';
    return null;
  }

  String? validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'Phone is required';
    if (!v.isValidPhone) return 'Enter a valid 10-digit number';
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Minimum 6 characters';
    return null;
  }

  String? validateConfirmPassword(String? v) {
    if (v != passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;
    errorMessage.value = '';
    isLoading.value = true;

    // 1. Create Firebase Auth user
    final authResult = await _auth.register(emailCtrl.text, passwordCtrl.text);
    await authResult.fold(
          (failure) async {
        errorMessage.value = failure.message;
        isLoading.value = false;
      },
          (credential) async {
        // 2. Create vendor profile in Firestore
        final vendorResult = await _repo.createVendor(
          name:         nameCtrl.text.trim(),
          businessName: businessCtrl.text.trim(),
          email:        emailCtrl.text.trim(),
          phone:        phoneCtrl.text.trim(),
          address:      addressCtrl.text.trim(),
          city:         cityCtrl.text.trim(),
          serviceType:  selectedService.value,
        );

        vendorResult.fold(
              (failure) {
            errorMessage.value = failure.message;
            isLoading.value = false;
          },
              (vendor) async {
            await LocalStorageService.setVendorId(vendor.id);
            isLoading.value = false;
            Get.offAllNamed(Routes.dashboard);
          },
        );
      },
    );
  }

  @override
  void onClose() {
    nameCtrl.dispose(); businessCtrl.dispose(); emailCtrl.dispose();
    phoneCtrl.dispose(); addressCtrl.dispose(); cityCtrl.dispose();
    passwordCtrl.dispose(); confirmPassCtrl.dispose();
    super.onClose();
  }
}