// lib/modules/profile/profile_controller.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/vendor_model.dart';
import '../../data/repositories/vendor_repository.dart';
import '../../services/auth_service.dart';
import '../../services/local_storage_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/dialogs/confirm_dialog.dart';

class ProfileController extends GetxController {
  final VendorRepository _vendorRepo = Get.find<VendorRepository>();
  final AuthService _auth            = Get.find<AuthService>();

  final formKey       = GlobalKey<FormState>();
  final nameCtrl      = TextEditingController();
  final businessCtrl  = TextEditingController();
  final phoneCtrl     = TextEditingController();
  final addressCtrl   = TextEditingController();
  final cityCtrl      = TextEditingController();

  final Rxn<VendorModel> vendor    = Rxn<VendorModel>();
  final Rxn<File>        newImage  = Rxn<File>();
  final RxBool  isEditing          = false.obs;
  final RxBool  isSaving           = false.obs;
  final RxBool  isLoggingOut       = false.obs;
  final RxString selectedService   = 'milk'.obs;

  StreamSubscription? _vendorSub;

  @override
  void onInit() {
    super.onInit();
    vendor.value = LocalStorageService.getVendor();
    _prefillForm();
    _listenToVendor();
  }

  void _listenToVendor() {
    final uid = _auth.uid;
    if (uid == null) return;
    _vendorSub = _vendorRepo.watchVendor(uid).listen((v) {
      if (v != null) {
        vendor.value = v;
        if (!isEditing.value) _prefillForm();
      }
    });
  }

  void _prefillForm() {
    final v = vendor.value;
    if (v == null) return;
    nameCtrl.text     = v.name;
    businessCtrl.text = v.businessName;
    phoneCtrl.text    = v.phone;
    addressCtrl.text  = v.address;
    cityCtrl.text     = v.city;
    selectedService.value = v.serviceTypeStr;
  }

  void toggleEdit() {
    if (isEditing.value) {
      // Cancel — restore original values
      _prefillForm();
      newImage.value = null;
    }
    isEditing.value = !isEditing.value;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) newImage.value = File(picked.path);
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (vendor.value == null) return;
    isSaving.value = true;

    final updated = vendor.value!.copyWith(
      name:           nameCtrl.text.trim(),
      businessName:   businessCtrl.text.trim(),
      phone:          phoneCtrl.text.trim(),
      address:        addressCtrl.text.trim(),
      city:           cityCtrl.text.trim(),
      serviceTypeStr: selectedService.value,
    );

    final result = await _vendorRepo.updateVendor(
        updated, newImage: newImage.value);

    result.fold(
          (f) => Get.snackbar('Error', f.message,
          snackPosition: SnackPosition.TOP),
          (_) {
        isEditing.value = false;
        newImage.value  = null;
        Get.snackbar('✅ Profile Updated',
            'Your profile has been saved.',
            snackPosition: SnackPosition.TOP);
      },
    );
    isSaving.value = false;
  }

  Future<void> logout() async {
    final confirm = await showConfirmDialog(
      title: 'Logout',
      message: 'Are you sure you want to logout from VendorTrack?',
      confirmLabel: 'Logout',
      isDangerous: true,
    );
    if (confirm != true) return;
    isLoggingOut.value = true;
    await _auth.logout();
    await LocalStorageService.clearAll();
    Get.offAllNamed(Routes.login);
  }

  @override
  void onClose() {
    _vendorSub?.cancel();
    nameCtrl.dispose();
    businessCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    super.onClose();
  }
}