// lib/modules/customers/add/add_customer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../widgets/inputs/app_text_field.dart';
import 'add_customer_controller.dart';

class AddCustomerScreen extends GetView<AddCustomerController> {
  const AddCustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditMode.value ? 'Edit Customer' : 'Add Customer')),
      ),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service type selector
              const Text('Service Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary, fontFamily: 'Poppins')),
              const SizedBox(height: 10),
              Obx(() => Wrap(
                spacing: 8, runSpacing: 8,
                children: controller.serviceOptions.map((opt) {
                  final isSelected = controller.selectedService.value == opt['value'];
                  return GestureDetector(
                    onTap: () => controller.selectedService.value = opt['value']!,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(opt['label']!,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontFamily: 'Poppins')),
                    ),
                  );
                }).toList(),
              )),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Customer Name *',
                hint: 'Ramesh Kumar',
                controller: controller.nameCtrl,
                validator: (v) => controller.validateRequired(v, 'Name'),
                prefix: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textHint),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Mobile Number *',
                hint: '9876543210',
                controller: controller.phoneCtrl,
                validator: controller.validatePhone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10)],
                prefix: const Icon(Icons.phone_outlined, size: 18, color: AppColors.textHint),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Alternate Number',
                hint: '9876543211 (optional)',
                controller: controller.altPhoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10)],
                prefix: const Icon(Icons.phone_outlined, size: 18, color: AppColors.textHint),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Delivery Address *',
                hint: '123, Main Street, Andheri West',
                controller: controller.addressCtrl,
                validator: (v) => controller.validateRequired(v, 'Address'),
                maxLines: 2,
                prefix: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textHint),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Landmark',
                hint: 'Near post office (optional)',
                controller: controller.landmarkCtrl,
                prefix: const Icon(Icons.place_outlined, size: 18, color: AppColors.textHint),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Notes',
                hint: 'Delivery preference, gate code, etc.',
                controller: controller.notesCtrl,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                prefix: const Icon(Icons.notes_rounded, size: 18, color: AppColors.textHint),
              ),
              const SizedBox(height: 28),
              Obx(() => PrimaryButton(
                label: controller.isEditMode.value ? 'Update Customer' : 'Add Customer',
                onTap: controller.save,
                isLoading: controller.isLoading.value,
                icon: controller.isEditMode.value
                    ? Icons.check_rounded
                    : Icons.person_add_rounded,
              )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}