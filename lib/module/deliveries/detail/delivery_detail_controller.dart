// lib/module/deliveries/detail/delivery_detail_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/delivery_model.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../../services/local_storage_service.dart';

class DeliveryDetailController extends GetxController {
  final DeliveryRepository _repo = Get.find<DeliveryRepository>();

  final Rx<DeliveryModel?> delivery = Rx<DeliveryModel?>(null);
  final RxBool isMarking = false.obs;

  String? get vendorId => LocalStorageService.getVendor()?.id;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is DeliveryModel) {
      delivery.value = args;
    }
  }

  Future<void> markDelivery(DeliveryStatus status, {String? notes}) async {
    if (vendorId == null || delivery.value == null) return;
    isMarking.value = true;

    final result = await _repo.updateDeliveryStatus(
        vendorId!, delivery.value!, status, notes: notes);

    result.fold(
          (f) => Get.snackbar('Error', f.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          colorText: Colors.white),
          (_) {
        // Update local delivery object
        delivery.value = delivery.value!.copyWith(
          statusStr: status.name,
          deliveredAt: status == DeliveryStatus.delivered ? DateTime.now() : null,
          notes: notes ?? delivery.value!.notes,
        );
        final label = status == DeliveryStatus.delivered ? '✅ Delivered'
            : status == DeliveryStatus.missed ? '❌ Missed'
            : status == DeliveryStatus.pending ? '🔄 Re-opened'
            : 'Updated';
        Get.snackbar(label, '${delivery.value!.customerName} updated.',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 2));
      },
    );
    isMarking.value = false;
  }

  void showNotesDialog(DeliveryStatus status) {
    final notesCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          status == DeliveryStatus.missed ? 'Reason for Missing' : 'Add Notes',
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: status == DeliveryStatus.missed
                ? 'e.g., Customer not home, dog at gate...'
                : 'Add delivery notes...',
            hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: status == DeliveryStatus.missed ? AppColors.error : AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              markDelivery(status, notes: notesCtrl.text.trim().isEmpty
                  ? null : notesCtrl.text.trim());
            },
            child: Text(status == DeliveryStatus.missed ? 'Mark Missed' : 'Confirm',
                style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void showAddNotesDialog() {
    final notesCtrl = TextEditingController(text: delivery.value?.notes ?? '');
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add / Edit Notes',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: TextField(
          controller: notesCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter notes...',
            hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              markDelivery(delivery.value!.status,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim());
            },
            child: const Text('Save',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}