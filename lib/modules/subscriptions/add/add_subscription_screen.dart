// lib/modules/subscriptions/add/add_subscription_screen.dart
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
import '../../../data/models/plan_model.dart';
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

              // ── STEP 2: Choose Plan Templates ───────────────────────────
              _SectionHeader(
                step: '2',
                label: 'Add Plan Templates',
                icon: Icons.assignment_outlined,
              ),
              const SizedBox(height: 10),
              _PlanBasketSection(controller: controller),

              const SizedBox(height: 20),
              const _Divider(),
              const SizedBox(height: 20),

              // ── STEP 3: Start Date ─────────────────────────────────────
              _SectionHeader(
                step: '3',
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
          child: const Row(children: [
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

// Plan Templates Basket Section
class _PlanBasketSection extends StatelessWidget {
  final AddSubscriptionController controller;
  const _PlanBasketSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown + Add button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Obx(() {
                final plans = controller.activePlans;
                return DropdownButtonFormField<PlanModel>(
                  value: controller.selectedDropdownPlan.value,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    prefixIcon: const Icon(Icons.assignment_outlined, size: 20, color: AppColors.textHint),
                    hintText: 'Choose plan template',
                  ),
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary, fontFamily: 'Poppins',
                  ),
                  items: plans.map((p) => DropdownMenuItem<PlanModel>(
                    value: p,
                    child: Text('${p.name} (₹${p.pricePerDelivery.toStringAsFixed(0)})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14, fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        )),
                  )).toList(),
                  onChanged: (plan) {
                    controller.selectedDropdownPlan.value = plan;
                  },
                );
              }),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final selected = controller.selectedDropdownPlan.value;
              return SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: selected == null ? null : () => controller.addPlan(selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),

        const SizedBox(height: 12),

        // Selected Basket Items
        Obx(() {
          final items = controller.selectedPlans;
          if (items.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: const Column(
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 28, color: AppColors.textHint),
                  SizedBox(height: 8),
                  Text(
                    'No plan templates added yet.',
                    style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Choose a plan above and click "Add".',
                    style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final item = items[index];
              return _BasketItemTile(
                item: item,
                onRemove: () => controller.removePlan(item.id),
              );
            },
          );
        }),

        // Summary Box
        Obx(() {
          if (controller.selectedPlans.isEmpty) return const SizedBox.shrink();
          return Column(
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Delivery Rate',
                          style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '₹${controller.totalDeliveryRate.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Monthly Revenue',
                          style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '~₹${controller.estimatedMonthlyRevenue.toStringAsFixed(0)}/month',
                          style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

// Basket Item Tile
class _BasketItemTile extends StatelessWidget {
  final SelectedPlanItem item;
  final VoidCallback onRemove;

  const _BasketItemTile({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final plan = item.plan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assignment_outlined, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${plan.quantity} ${plan.unit}  •  ${plan.frequencyStr == 'daily' ? 'Daily' : plan.frequencyStr == 'twice_daily' ? '2× Daily' : plan.frequencyStr == 'thrice_daily' ? '3× Daily' : plan.frequencyStr == 'alternate' ? 'Alt. Days' : 'Weekly'}',
                  style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${plan.pricePerDelivery.toStringAsFixed(0)}',
            style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onRemove,
          ),
        ],
      ),
    );
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
