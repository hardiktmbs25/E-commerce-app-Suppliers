// lib/module/subscriptions/add/add_subscription_screen.dart
//
// DESIGN GOALS (for less-educated local suppliers):
//  • Very large touch targets (min 52px height)
//  • Minimal text – icons + labels carry the meaning
//  • No nested cards – flat sections with clear dividers
//  • Step-by-step visual flow: Customer → Service info → Frequency → Time → Save
//  • Inline price preview updates as user types

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/service_constants.dart';
import '../../../data/models/customer_model.dart';
import '../widgets/frequency_chip.dart';
import '../widgets/service_badge.dart';
import '../widgets/time_slot_picker.dart';
import 'add_subscription_controller.dart';

class AddSubscriptionScreen extends GetView<AddSubscriptionController> {
  const AddSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'New Subscription',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── STEP 1: Customer ───────────────────────────────────────
              _SectionHeader(
                step: '1',
                label: 'Who is this for?',
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 10),
              _CustomerPicker(controller: controller),

              const SizedBox(height: 20),
              const _Divider(),
              const SizedBox(height: 20),

              // ── STEP 2: Service (locked to vendor's service) ───────────
              _SectionHeader(
                step: '2',
                label: 'Service',
                icon: Icons.local_shipping_rounded,
              ),
              const SizedBox(height: 10),
              ServiceBadge(
                service: controller.selectedService.value,
                large: true,
              ),
              const SizedBox(height: 4),
              const Text(
                'Service is set based on your account',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 20),
              const _Divider(),
              const SizedBox(height: 20),

              // ── STEP 3: Quantity + Unit ────────────────────────────────
              _SectionHeader(
                step: '3',
                label: 'Quantity & Unit',
                icon: Icons.scale_rounded,
              ),
              const SizedBox(height: 10),
              Row(children: [
                // Quantity field
                Expanded(
                  child: _BigInputField(
                    label: 'Quantity',
                    controller: controller.quantityCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (v) => controller.validateNumber(v, 'Quantity'),
                    prefix: const Icon(Icons.numbers_rounded,
                        size: 20, color: AppColors.textHint),
                  ),
                ),
                const SizedBox(width: 12),
                // Unit dropdown
                Expanded(
                  child: _UnitDropdown(controller: controller),
                ),
              ]),

              const SizedBox(height: 16),

              // ── Price ──────────────────────────────────────────────────
              _BigInputField(
                label: 'Price per Unit (₹)',
                controller: controller.pricePerUnitCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (v) => controller.validateNumber(v, 'Price'),
                prefix: const Icon(Icons.currency_rupee_rounded,
                    size: 20, color: AppColors.textHint),
              ),

              const SizedBox(height: 10),

              // ── Live price preview ─────────────────────────────────────
              if (controller.pricePerDelivery > 0)
                _PricePreview(
                  pricePerDelivery: controller.pricePerDelivery,
                  frequency: controller.selectedFrequency.value,
                ),

              const SizedBox(height: 20),
              const _Divider(),
              const SizedBox(height: 20),

              // ── STEP 4: Frequency ──────────────────────────────────────
              _SectionHeader(
                step: '4',
                label: 'How often?',
                icon: Icons.repeat_rounded,
              ),
              const SizedBox(height: 10),
              FrequencyChipRow(
                selected: controller.selectedFrequency.value,
                onChanged: (f) => controller.selectedFrequency.value = f,
              ),

              const SizedBox(height: 20),
              const _Divider(),
              const SizedBox(height: 20),

              // ── STEP 5: Delivery Time(s) ───────────────────────────────
              _SectionHeader(
                step: '5',
                label: controller.requiredSlotCount > 1
                    ? 'Delivery Times (${controller.requiredSlotCount} required)'
                    : 'Delivery Time',
                icon: Icons.schedule_rounded,
              ),
              const SizedBox(height: 10),
              TimeSlotPicker(
                slots:         controller.deliveryTimeSlots.toList(),
                requiredCount: controller.requiredSlotCount,
                onTapSlot:     controller.pickTimeSlot,
              ),

              const SizedBox(height: 20),
              const _Divider(),
              const SizedBox(height: 20),

              // ── STEP 6: Start Date ─────────────────────────────────────
              _SectionHeader(
                step: '6',
                label: 'Start Date',
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(height: 10),
              _DatePickerButton(
                date: controller.startDate.value,
                onTap: controller.pickStartDate,
              ),

              const SizedBox(height: 20),
              const _Divider(),
              const SizedBox(height: 20),

              // ── Optional Notes ─────────────────────────────────────────
              const _SectionHeader(
                step: '',
                label: 'Notes (optional)',
                icon: Icons.notes_rounded,
              ),
              const SizedBox(height: 10),
              _BigInputField(
                label: '',
                controller: controller.notesCtrl,
                maxLines: 3,
                hint: 'e.g. Leave at gate',
                prefix: null,
              ),

              const SizedBox(height: 28),

              // ── Save Button ────────────────────────────────────────────
              _SaveButton(controller: controller),
            ],
          )),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String step;
  final String label;
  final IconData icon;

  const _SectionHeader({
    required this.step,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (step.isNotEmpty) ...[
        Container(
          width: 28, height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(step,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: Colors.white, fontFamily: 'Poppins')),
        ),
        const SizedBox(width: 10),
      ],
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            )),
      ),
    ]);
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppColors.divider, thickness: 1, height: 1);
}

// Customer picker – large dropdown with avatar
class _CustomerPicker extends StatelessWidget {
  final AddSubscriptionController controller;
  const _CustomerPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final customers = controller.customers;
      if (customers.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No active customers found. Add a customer first.',
                style: TextStyle(fontSize: 13, color: AppColors.warning,
                    fontFamily: 'Poppins'),
              ),
            ),
          ]),
        );
      }

      return DropdownButtonFormField<String>(
        value: controller.selectedCustomer.value?.id,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          prefixIcon: const Icon(Icons.person_search_rounded,
              size: 22, color: AppColors.textHint),
          hintText: 'Choose customer',
        ),
        style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, fontFamily: 'Poppins',
        ),
        items: customers
            .map((c) => DropdownMenuItem(
          value: c.id,
          child: Text(c.name,
              style: const TextStyle(
                fontSize: 15, fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              )),
        ))
            .toList(),
        onChanged: (id) {
          controller.selectedCustomer.value =
              controller.customers.firstWhereOrNull((c) => c.id == id);
        },
        validator: (v) => v == null ? 'Please select a customer' : null,
      );
    });
  }
}

// Unit dropdown – auto-populated from service
class _UnitDropdown extends StatelessWidget {
  final AddSubscriptionController controller;
  const _UnitDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => DropdownButtonFormField<String>(
      value: controller.selectedUnit.value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Unit',
        labelStyle: const TextStyle(
            fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Poppins'),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, fontFamily: 'Poppins',
      ),
      items: controller.unitOptions
          .map((u) => DropdownMenuItem(
        value: u,
        child: Text(u),
      ))
          .toList(),
      onChanged: (v) {
        if (v != null) controller.selectedUnit.value = v;
      },
    ));
  }
}

// Big text input with consistent styling
class _BigInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final int maxLines;

  const _BigInputField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.prefix,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        labelText: label.isEmpty ? null : label,
        hintText: hint,
        labelStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontFamily: 'Poppins'),
        hintStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textHint,
            fontFamily: 'Poppins'),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: prefix != null
            ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: prefix,
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

// Live price + monthly estimate preview
class _PricePreview extends StatelessWidget {
  final double pricePerDelivery;
  final DeliveryFrequency frequency;

  const _PricePreview({
    required this.pricePerDelivery,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    final monthly = pricePerDelivery *
        FrequencyConstants.monthlyDeliveries(frequency);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded,
            size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹${pricePerDelivery.toStringAsFixed(2)} per delivery',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                '~₹${monthly.toStringAsFixed(0)} estimated/month',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// Start date selector button
class _DatePickerButton extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerButton({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')} / '
        '${date.month.toString().padLeft(2, '0')} / '
        '${date.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.event_rounded,
              size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            formatted,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: AppColors.textHint),
        ]),
      ),
    );
  }
}

// Save button with loading state
class _SaveButton extends StatelessWidget {
  final AddSubscriptionController controller;
  const _SaveButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : controller.save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
        child: controller.isLoading.value
            ? const SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor:
            AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded,
                size: 22, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Add Subscription',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    ));
  }
}