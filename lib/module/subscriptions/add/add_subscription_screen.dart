// lib/modules/subscriptions/add/add_subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/subscription_model.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../widgets/inputs/app_text_field.dart';
import 'add_subscription_controller.dart';

class AddSubscriptionScreen extends GetView<AddSubscriptionController> {
  const AddSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Subscription')),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Customer selector
            const Text('Select Customer',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary, fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedCustomer.value?.id,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.people_outline_rounded, size: 18,
                    color: AppColors.textHint),
              ),
              hint: const Text('Choose customer'),
              items: controller.customers.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.name,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              )).toList(),
              onChanged: (id) {
                controller.selectedCustomer.value =
                    controller.customers.firstWhereOrNull((c) => c.id == id);
              },
              validator: (v) => v == null ? 'Please select a customer' : null,
            )),
            const SizedBox(height: 16),

            // Service type
            AppDropdownField<String>(
              label: 'Service Type',
              value: controller.selectedService.value,
              hint: 'Select service',
              items: controller.serviceOptions.map((s) =>
                  DropdownMenuItem(value: s,
                      child: Text(s.capitalize!,
                          style: const TextStyle(fontFamily: 'Poppins')))).toList(),
              onChanged: (v) => controller.selectedService.value = v!,
            ),
            const SizedBox(height: 16),

            // Frequency
            const Text('Delivery Frequency',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary, fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            Obx(() => Wrap(
              spacing: 8, runSpacing: 8,
              children: SubscriptionFrequency.values.map((f) {
                final isSelected = controller.selectedFrequency.value == f;
                return GestureDetector(
                  onTap: () => controller.selectedFrequency.value = f,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(_freqLabel(f),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontFamily: 'Poppins')),
                  ),
                );
              }).toList(),
            )),
            const SizedBox(height: 16),

            // Quantity + Unit row
            Row(children: [
              Expanded(child: AppTextField(
                label: 'Quantity',
                hint: '1',
                controller: controller.quantityCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                validator: (v) => controller.validateNumber(v, 'Quantity'),
              )),
              const SizedBox(width: 12),
              Expanded(child: Obx(() => AppDropdownField<String>(
                label: 'Unit',
                value: controller.selectedUnit.value,
                items: controller.unitOptions.map((u) =>
                    DropdownMenuItem(value: u,
                        child: Text(u, style: const TextStyle(fontFamily: 'Poppins')))).toList(),
                onChanged: (v) => controller.selectedUnit.value = v!,
              ))),
            ]),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Price per Unit (₹)',
              hint: '30.00',
              controller: controller.pricePerUnitCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              validator: (v) => controller.validateNumber(v, 'Price'),
              prefix: const Icon(Icons.currency_rupee_rounded, size: 18,
                  color: AppColors.textHint),
            ),
            const SizedBox(height: 8),

            // Live price preview
            Obx(() {
              final ppd = controller.pricePerDelivery;
              if (ppd <= 0) return const SizedBox();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('₹${ppd.toStringAsFixed(2)} per delivery',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.primary, fontFamily: 'Poppins')),
                ]),
              );
            }),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Delivery Slot',
              hint: '07:00 AM - 08:00 AM',
              controller: controller.slotCtrl,
              validator: (v) => controller.validateRequired(v, 'Delivery slot'),
              prefix: const Icon(Icons.schedule_rounded, size: 18, color: AppColors.textHint),
            ),
            const SizedBox(height: 28),

            Obx(() => PrimaryButton(
              label: 'Add Subscription',
              onTap: controller.save,
              isLoading: controller.isLoading.value,
              icon: Icons.add_circle_outline_rounded,
            )),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  String _freqLabel(SubscriptionFrequency f) {
    switch (f) {
      case SubscriptionFrequency.daily:        return 'Daily';
      case SubscriptionFrequency.alternateDay: return 'Alt. Day';
      case SubscriptionFrequency.weekdays:     return 'Weekdays';
      case SubscriptionFrequency.weekends:     return 'Weekends';
      case SubscriptionFrequency.weekly:       return 'Weekly';
      case SubscriptionFrequency.custom:       return 'Custom';
    }
  }
}