// lib/module/subscriptions/global_plans/global_plans_screen.dart
//
// Changes vs original
// ───────────────────
// • Add Plan sheet uses PlanServiceSelector (visual chip grid) instead of
//   a plain dropdown — more accessible for less-educated users.
// • Unit dropdown is rebuilt reactively from the chosen service type.
// • Frequency dropdown uses kFrequencies / kFrequencyLabels from
//   plan_constants.dart (includes twice_daily / thrice_daily).
// • Time-slot picker shows all vendor slots as tappable tiles (PlanSlotPicker).
// • Form is split into logical step-sections with larger text (15–17 px)
//   and generous spacing so the UI is comfortable on small screens.
// • isSaving → per-form flags (planSaving / areaSaving / slotSaving).
// • Time-slot sheet uses Obx so the picked label updates without hacks.
// • _AddPlanSheet is a StatelessWidget backed fully by Obx — no setState.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/plan_constants.dart';
import '../../../data/models/delivery_area_model.dart';
import '../../../data/models/plan_model.dart';
import '../../../data/models/time_slot_model.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../widgets/common/shimmer_box.dart';
import '../../../widgets/inputs/app_text_field.dart';
import '../../../widgets/plan/plan_service_selector.dart';
import '../../../widgets/plan/plan_slot_picker.dart';
import 'global_plans_controller.dart';

class GlobalPlansScreen extends GetView<GlobalPlansController> {
  const GlobalPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Plan Templates',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
          ),
          actions: [
            Obx(() => _AddButton(
              tabIndex: controller.tabIndex.value,
              onPlans:  () => _showPlanSheet(context),
              onAreas:  () => _showAreaSheet(context),
              onSlots:  () => _showSlotSheet(context),
            )),
          ],
          bottom: TabBar(
            onTap: (i) => controller.tabIndex.value = i,
            tabs: const [
              Tab(text: 'Plans'),
              Tab(text: 'Areas'),
              Tab(text: 'Time Slots'),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _PlansTab(ctrl: controller),
            _AreasTab(ctrl: controller),
            _SlotsTab(ctrl: controller),
          ],
        ),
      ),
    );
  }

  void _showPlanSheet(BuildContext ctx) => showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddPlanSheet(ctrl: controller),
  );

  void _showAreaSheet(BuildContext ctx) => showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddAreaSheet(ctrl: controller),
  );

  void _showSlotSheet(BuildContext ctx) => showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddSlotSheet(ctrl: controller),
  );
}

// ── Add/FAB button in AppBar ──────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final int tabIndex;
  final VoidCallback onPlans, onAreas, onSlots;
  const _AddButton(
      {required this.tabIndex,
        required this.onPlans,
        required this.onAreas,
        required this.onSlots});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
      onPressed: tabIndex == 0 ? onPlans : tabIndex == 1 ? onAreas : onSlots,
      tooltip: tabIndex == 0 ? 'Add Plan' : tabIndex == 1 ? 'Add Area' : 'Add Slot',
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PLANS TAB
// ══════════════════════════════════════════════════════════════════════════════

class _PlansTab extends StatelessWidget {
  final GlobalPlansController ctrl;
  const _PlansTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingPlans.value) return const ShimmerList();
      if (ctrl.plans.isEmpty) {
        return EmptyState(
          icon: Icons.assignment_outlined,
          title: 'No Plans Yet',
          subtitle:
          'Create your first plan template.\nCustomers pick from these when subscribing.',
          actionLabel: 'Add Plan',
          onAction: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AddPlanSheet(ctrl: ctrl),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ctrl.plans.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _PlanCard(plan: ctrl.plans[i], ctrl: ctrl),
      );
    });
  }
}

class _PlanCard extends StatelessWidget {
  final PlanModel plan;
  final GlobalPlansController ctrl;
  const _PlanCard({required this.plan, required this.ctrl});

  Color _serviceColor(String s) {
    switch (s) {
      case 'milk':      return AppColors.milk;
      case 'water':     return AppColors.water;
      case 'newspaper': return AppColors.newspaper;
      case 'tiffin':    return AppColors.tiffin;
      default:          return AppColors.custom;
    }
  }

  IconData _serviceIcon(String s) {
    switch (s) {
      case 'milk':      return Icons.water_drop_rounded;
      case 'water':     return Icons.local_drink_rounded;
      case 'newspaper': return Icons.newspaper_rounded;
      case 'tiffin':    return Icons.lunch_dining_rounded;
      case 'grocery':   return Icons.shopping_basket_rounded;
      default:          return Icons.inventory_2_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _serviceColor(plan.serviceType);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_serviceIcon(plan.serviceType), size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins'),
                  ),
                  Text(
                    '${serviceLabel(plan.serviceType)}  •  ${frequencyLabel(plan.frequencyStr)}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'delete') ctrl.deletePlan(plan.id, plan.name);
                if (v == 'toggle') ctrl.togglePlanActive(plan);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(plan.isActive ? 'Deactivate' : 'Activate'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ]),
          const Divider(height: 20, color: AppColors.divider),
          // ── Stat row ────────────────────────────────────────────────
          Row(children: [
            _InfoChip(
                label: '${plan.quantity} ${unitLabel(plan.unit)}',
                icon: Icons.inventory_2_outlined),
            const SizedBox(width: 12),
            _InfoChip(
                label: '₹${plan.pricePerUnit}/${unitLabel(plan.unit)}',
                icon: Icons.currency_rupee_rounded),
            const Spacer(),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '₹${plan.pricePerDelivery.toStringAsFixed(0)}/delivery',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontFamily: 'Poppins'),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          _InfoChip(
            label: plan.deliveryAreaIds.isEmpty
                ? 'All Areas'
                : plan.deliveryAreaIds
                    .map((id) =>
                        ctrl.areas.firstWhereOrNull((a) => a.id == id)?.name ??
                        'Unknown')
                    .join(', '),
            icon: Icons.location_on_rounded,
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(plan.description,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontFamily: 'Poppins')),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AREAS TAB
// ══════════════════════════════════════════════════════════════════════════════

class _AreasTab extends StatelessWidget {
  final GlobalPlansController ctrl;
  const _AreasTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingAreas.value) return const ShimmerList();
      if (ctrl.areas.isEmpty) {
        return EmptyState(
          icon: Icons.location_on_outlined,
          title: 'No Delivery Areas',
          subtitle:
          'Add areas where you deliver.\nCustomers select their area when subscribing.',
          actionLabel: 'Add Area',
          onAction: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AddAreaSheet(ctrl: ctrl),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ctrl.areas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _AreaTile(area: ctrl.areas[i], ctrl: ctrl),
      );
    });
  }
}

class _AreaTile extends StatelessWidget {
  final DeliveryAreaModel area;
  final GlobalPlansController ctrl;
  const _AreaTile({required this.area, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.location_on_rounded,
              size: 20, color: AppColors.info),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(area.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins')),
              if (area.city != null || area.pincode != null)
                Text(
                  [
                    if (area.city != null) area.city!,
                    if (area.pincode != null) area.pincode!
                  ].join(' • '),
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                      fontFamily: 'Poppins'),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.error, size: 20),
          onPressed: () => ctrl.deleteArea(area.id, area.name),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TIME-SLOTS TAB
// ══════════════════════════════════════════════════════════════════════════════

class _SlotsTab extends StatelessWidget {
  final GlobalPlansController ctrl;
  const _SlotsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingSlots.value) return const ShimmerList();
      if (ctrl.timeSlots.isEmpty) {
        return EmptyState(
          icon: Icons.schedule_rounded,
          title: 'No Time Slots',
          subtitle: 'Add the time windows in which you deliver.',
          actionLabel: 'Add Time Slot',
          onAction: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AddSlotSheet(ctrl: ctrl),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ctrl.timeSlots.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) =>
            _SlotTile(slot: ctrl.timeSlots[i], ctrl: ctrl),
      );
    });
  }
}

class _SlotTile extends StatelessWidget {
  final TimeSlotModel slot;
  final GlobalPlansController ctrl;
  const _SlotTile({required this.slot, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.access_time_rounded,
              size: 20, color: AppColors.success),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(slot.label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins')),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.error, size: 20),
          onPressed: () => ctrl.deleteTimeSlot(slot.id, slot.label),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ADD PLAN SHEET  (simplified, large-text, step-by-step layout)
// ══════════════════════════════════════════════════════════════════════════════

class _AddPlanSheet extends StatelessWidget {
  final GlobalPlansController ctrl;
  const _AddPlanSheet({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Form(
          key: ctrl.planFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Create New Plan',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fill in the details below to set up a plan for your customers.',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 24),

              // ── Step 1: Plan name ─────────────────────────────────────
              _StepLabel(step: '1', label: 'Plan Name'),
              const SizedBox(height: 8),
              AppTextField(
                label: 'Give your plan a name',
                hint: 'e.g.  Daily Milk – 1 Litre',
                controller: ctrl.planNameCtrl,
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 22),

              // ── Step 2: Service type ──────────────────────────────────
              _StepLabel(step: '2', label: 'Service Type'),
              const SizedBox(height: 10),
              PlanServiceSelector(
                selected:  ctrl.selectedService,
                onChanged: ctrl.onServiceChanged,
                allowedServices: [ctrl.vendorService],
              ),
              const SizedBox(height: 22),

              // ── Step 3: Frequency ─────────────────────────────────────
              _StepLabel(step: '3', label: 'Delivery Frequency'),
              const SizedBox(height: 8),
              Obx(() => AppDropdownField<String>(
                label: 'How often do you deliver?',
                value: ctrl.selectedFrequency.value,
                items: kFrequencies
                    .map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(frequencyLabel(f),
                      style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 14)),
                ))
                    .toList(),
                onChanged: ctrl.onFrequencyChanged,
              )),
              const SizedBox(height: 22),

              // ── Step 4: Quantity + Unit ───────────────────────────────
              _StepLabel(step: '4', label: 'How Much Per Delivery?'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    label: 'Quantity',
                    hint: '1',
                    controller: ctrl.planQtyCtrl,
                    onChanged: (v) {
                      ctrl.quantity.value =
                          double.tryParse(v.trim()) ?? 0;
                    },
                    keyboardType:
                    const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      )
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Required';
                      }
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) {
                        return 'Must be > 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Obx(() => AppDropdownField<String>(
                    label: 'Unit',
                    value: ctrl.selectedUnit.value,
                    items: ctrl.unitOptions
                        .map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(unitLabel(u),
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 14)),
                    ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) ctrl.selectedUnit.value = v;
                    },
                  )),
                ),
              ]),
              const SizedBox(height: 22),

              // ── Step 5: Price ─────────────────────────────────────────

              _StepLabel(step: '5', label: 'Price per Unit'),

              const SizedBox(height: 8),

              AppTextField(
                label: 'Price (₹)',
                hint: '30',
                controller: ctrl.planPriceCtrl,

                onChanged: (v) {
                  ctrl.price.value =
                      double.tryParse(v.trim()) ?? 0;
                },

                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),

                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*'),
                  )
                ],

                prefix: const Icon(
                  Icons.currency_rupee_rounded,
                  size: 18,
                  color: AppColors.textHint,
                ),

                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Price is required';
                  }

                  final n = double.tryParse(v);

                  if (n == null || n <= 0) {
                    return 'Enter a valid price';
                  }

                  return null;
                },
              ),
              /// FIXED PREVIEW
              Obx(() {
                final preview = ctrl.planPreviewPrice;
                if (preview <= 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calculate_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${preview.toStringAsFixed(2)} per delivery slot',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 22),

              // ── Step 6: Delivery time slots ───────────────────────────
              Obx(() {
                final count = ctrl.requiredSlotCount;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepLabel(
                      step: '6',
                      label: count == 1
                          ? 'Delivery Time'
                          : 'Delivery Times ($count needed)',
                    ),
                    const SizedBox(height: 8),
                    PlanSlotPicker(
                      slots: List<TimeSlotModel>.from(
                        ctrl.timeSlots,
                      ),
                      selectedIds: List<String>.from(
                        ctrl.selectedSlotIds,
                      ),
                      required: count,
                      onToggle: ctrl.toggleSlotId,
                    ),
                  ],
                );
              }),

              const SizedBox(height: 22),

              // ── Step 7: Delivery Areas ───────────────────────────────
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepLabel(
                    step: '7',
                    label: 'Delivery Areas',
                  ),
                  const SizedBox(height: 8),
                  if (ctrl.areas.isEmpty)
                    const Text(
                      'No delivery areas added yet. Please add an area in the Areas tab.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                        fontFamily: 'Poppins',
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ctrl.areas.map((area) {
                        final isSelected = ctrl.selectedAreaIds.contains(area.id);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(
                            area.name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          backgroundColor: AppColors.surfaceVariant,
                          onSelected: (_) => ctrl.toggleAreaId(area.id),
                        );
                      }).toList(),
                    ),
                ],
              )),

              const SizedBox(height: 22),
              // ── Step 8: Optional description ──────────────────────────
              _StepLabel(step: '8', label: 'Description (optional)'),
              const SizedBox(height: 8),
              AppTextField(
                label: 'Short note for customers',
                hint: 'e.g. Best for a family of 3–4',
                controller: ctrl.planDescCtrl,
                maxLines: 2,
              ),
              const SizedBox(height: 28),

              // ── Save ──────────────────────────────────────────────────
              Obx(() => PrimaryButton(
                label: 'Create Plan',
                onTap: ctrl.savePlan,
                isLoading: ctrl.planSaving.value,
                icon: Icons.check_circle_outline_rounded,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ADD AREA SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _AddAreaSheet extends StatelessWidget {
  final GlobalPlansController ctrl;
  const _AddAreaSheet({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Form(
        key: ctrl.areaFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Add Delivery Area',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Area Name',
              hint: 'e.g. Andheri West',
              controller: ctrl.areaNameCtrl,
              prefix: const Icon(Icons.location_on_outlined,
                  size: 18, color: AppColors.textHint),
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'Area name is required' : null,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: AppTextField(
                  label: 'Pincode (optional)',
                  hint: '400058',
                  controller: ctrl.areaPinCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'City (optional)',
                  hint: 'Mumbai',
                  controller: ctrl.areaCityCtrl,
                ),
              ),
            ]),
            const SizedBox(height: 24),
            Obx(() => PrimaryButton(
              label: 'Add Area',
              onTap: ctrl.saveArea,
              isLoading: ctrl.areaSaving.value,
              icon: Icons.add_location_alt_outlined,
            )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ADD SLOT SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _AddSlotSheet extends StatelessWidget {
  final GlobalPlansController ctrl;
  const _AddSlotSheet({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Form(
        key: ctrl.slotFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Add Time Slot',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap the button below to pick a delivery window.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 22),

            // Time picker button — shows picked label reactively via Obx
            Obx(() {
              final hasLabel = ctrl.pickedSlotLabel.value.isNotEmpty;
              return GestureDetector(
                onTap: () => ctrl.pickTime(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: hasLabel
                        ? AppColors.primary.withValues(alpha: 0.06)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasLabel
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.border,
                      width: hasLabel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: hasLabel
                          ? AppColors.primary
                          : AppColors.textHint,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        hasLabel
                            ? ctrl.pickedSlotLabel.value
                            : 'Tap to pick start & end time',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: hasLabel
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: hasLabel
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                    if (hasLabel)
                      const Icon(Icons.edit_rounded,
                          size: 16, color: AppColors.primary),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 12),

            // Validated hidden field for the label
            AppTextField(
              label: 'Slot label (auto-filled)',
              hint: 'e.g. 6:00 AM – 7:00 AM',
              controller: ctrl.slotLabelCtrl,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please pick a time range first'
                  : null,
            ),
            const SizedBox(height: 26),

            Obx(() => PrimaryButton(
              label: 'Save Time Slot',
              onTap: ctrl.saveTimeSlot,
              isLoading: ctrl.slotSaving.value,
              icon: Icons.schedule_rounded,
            )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ══════════════════════════════════════════════════════════════════════════════

/// Numbered step label used in the plan form.
class _StepLabel extends StatelessWidget {
  final String step;
  final String label;
  const _StepLabel({required this.step, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          step,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Poppins'),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        label,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins'),
      ),
    ]);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.textHint),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins')),
    ]);
  }
}