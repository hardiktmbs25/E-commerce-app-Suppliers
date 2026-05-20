// lib/module/subscriptions/global_plans/global_plans_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/delivery_area_model.dart';
import '../../../data/models/plan_model.dart';
import '../../../data/models/time_slot_model.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../widgets/common/shimmer_box.dart';
import '../../../widgets/inputs/app_text_field.dart';
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
          title: const Text('Plan Templates',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          actions: [
            Obx(() => _AddButton(
              tabIndex: controller.tabIndex.value,
              onPlans: () => _showAddPlanSheet(context),
              onAreas: () => _showAddAreaSheet(context),
              onSlots: () => _showAddSlotSheet(context),
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

  // ── Add Plan Bottom Sheet ──────────────────────────────────────────────
  void _showAddPlanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPlanSheet(ctrl: controller),
    );
  }

  void _showAddAreaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAreaSheet(ctrl: controller),
    );
  }

  void _showAddSlotSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSlotSheet(ctrl: controller),
    );
  }
}

// ── Add Button ─────────────────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final int tabIndex;
  final VoidCallback onPlans, onAreas, onSlots;

  const _AddButton(
      {required this.tabIndex, required this.onPlans, required this.onAreas, required this.onSlots});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
      onPressed: tabIndex == 0 ? onPlans : tabIndex == 1 ? onAreas : onSlots,
      tooltip: tabIndex == 0 ? 'Add Plan' : tabIndex == 1 ? 'Add Area' : 'Add Slot',
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// PLANS TAB
// ══════════════════════════════════════════════════════════════════════════
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
          subtitle: 'Create your first plan template.\nCustomers will pick from these when subscribing.',
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

  @override
  Widget build(BuildContext context) {
    final color = _serviceColor(plan.serviceType);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_serviceIcon(plan.serviceType), size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary, fontFamily: 'Poppins')),
                Text('${plan.serviceType.capitalize} • ${_freqLabel(plan.frequencyStr)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary,
                        fontFamily: 'Poppins')),
              ],
            )),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'delete') ctrl.deletePlan(plan.id, plan.name);
                if (v == 'toggle') ctrl.togglePlanActive(plan);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'toggle',
                    child: Text(plan.isActive ? 'Deactivate' : 'Activate')),
                const PopupMenuItem(value: 'delete',
                    child: Text('Delete', style: TextStyle(color: AppColors.error))),
              ],
            ),
          ]),
          const Divider(height: 20, color: AppColors.divider),
          Row(children: [
            _InfoChip(label: '${plan.quantity} ${plan.unit}', icon: Icons.inventory_2_outlined),
            const SizedBox(width: 12),
            _InfoChip(label: '₹${plan.pricePerUnit}/unit', icon: Icons.currency_rupee_rounded),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('₹${plan.pricePerDelivery.toStringAsFixed(0)}/delivery',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.primary, fontFamily: 'Poppins')),
            ),
          ]),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(plan.description,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint,
                    fontFamily: 'Poppins')),
          ],
        ],
      ),
    );
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

  String _freqLabel(String f) {
    switch (f) {
      case 'daily':        return 'Daily';
      case 'alternateDay': return 'Alternate Day';
      case 'weekdays':     return 'Weekdays';
      case 'weekends':     return 'Weekends';
      case 'weekly':       return 'Weekly';
      default:             return 'Custom';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// AREAS TAB
// ══════════════════════════════════════════════════════════════════════════
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
          subtitle: 'Add areas where you deliver.\nCustomers will select their area when subscribing.',
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
          child: const Icon(Icons.location_on_rounded, size: 20, color: AppColors.info),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(area.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, fontFamily: 'Poppins')),
            if (area.city != null || area.pincode != null)
              Text([if (area.city != null) area.city!, if (area.pincode != null) area.pincode!].join(' • '),
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Poppins')),
          ],
        )),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
          onPressed: () => ctrl.deleteArea(area.id, area.name),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// TIME SLOTS TAB
// ══════════════════════════════════════════════════════════════════════════
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
          subtitle: 'Add delivery time slots available for your customers.',
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
        itemBuilder: (_, i) => _SlotTile(slot: ctrl.timeSlots[i], ctrl: ctrl),
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
          child: const Icon(Icons.access_time_rounded, size: 20, color: AppColors.success),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(slot.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, fontFamily: 'Poppins'))),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
          onPressed: () => ctrl.deleteTimeSlot(slot.id, slot.label),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ADD PLAN SHEET
// ══════════════════════════════════════════════════════════════════════════
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
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: ctrl.planFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('New Plan Template',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary, fontFamily: 'Poppins')),
              const SizedBox(height: 20),

              AppTextField(
                label: 'Plan Name',
                hint: 'e.g. Silver Milk Plan',
                controller: ctrl.planNameCtrl,
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),

              // Service Type
              AppDropdownField<String>(
                label: 'Service Type',
                value: ctrl.selectedPlanService.value,
                items: ctrl.serviceOptions.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.capitalize!, style: const TextStyle(fontFamily: 'Poppins')),
                )).toList(),
                onChanged: (v) { if (v != null) ctrl.selectedPlanService.value = v; },
              ),
              const SizedBox(height: 14),

              // Frequency
              AppDropdownField<String>(
                label: 'Frequency',
                value: ctrl.selectedPlanFrequency.value,
                items: ctrl.frequencyOptions.map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(_freqLabel(f), style: const TextStyle(fontFamily: 'Poppins')),
                )).toList(),
                onChanged: (v) { if (v != null) ctrl.selectedPlanFrequency.value = v; },
              ),
              const SizedBox(height: 14),

              // Qty + Unit
              Row(children: [
                Expanded(child: AppTextField(
                  label: 'Quantity',
                  hint: '1',
                  controller: ctrl.planQtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid';
                    return null;
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: AppDropdownField<String>(
                  label: 'Unit',
                  value: ctrl.selectedPlanUnit.value,
                  items: ctrl.unitOptions.map((u) => DropdownMenuItem(
                    value: u, child: Text(u, style: const TextStyle(fontFamily: 'Poppins')),
                  )).toList(),
                  onChanged: (v) { if (v != null) ctrl.selectedPlanUnit.value = v; },
                )),
              ]),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Price Per Unit (₹)',
                hint: '30',
                controller: ctrl.planPriceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                prefix: const Icon(Icons.currency_rupee_rounded, size: 18, color: AppColors.textHint),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid';
                  return null;
                },
              ),

              // Live price preview
              if (ctrl.planPreviewPrice > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('₹${ctrl.planPreviewPrice.toStringAsFixed(2)} per delivery',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppColors.primary, fontFamily: 'Poppins')),
                  ]),
                ),
              ],
              const SizedBox(height: 14),

              AppTextField(
                label: 'Description (optional)',
                hint: 'e.g. Best for families with 2-3 members',
                controller: ctrl.planDescCtrl,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Create Plan',
                onTap: ctrl.savePlan,
                isLoading: ctrl.isSaving.value,
                icon: Icons.add_circle_outline_rounded,
              ),
            ],
          )),
        ),
      );
  }

  String _freqLabel(String f) {
    switch (f) {
      case 'daily':        return 'Daily';
      case 'alternateDay': return 'Alternate Day';
      case 'weekdays':     return 'Weekdays';
      case 'weekends':     return 'Weekends';
      case 'weekly':       return 'Weekly';
      default:             return 'Custom';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ADD AREA SHEET
// ══════════════════════════════════════════════════════════════════════════
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
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: ctrl.areaFormKey,
        child: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Add Delivery Area',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, fontFamily: 'Poppins')),
            const SizedBox(height: 20),

            AppTextField(
              label: 'Area Name',
              hint: 'e.g. Andheri West',
              controller: ctrl.areaNameCtrl,
              prefix: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textHint),
              validator: (v) => v == null || v.trim().isEmpty ? 'Area name is required' : null,
            ),
            const SizedBox(height: 14),

            Row(children: [
              Expanded(child: AppTextField(
                label: 'Pincode (optional)',
                hint: '400058',
                controller: ctrl.areaPinCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(
                label: 'City (optional)',
                hint: 'Mumbai',
                controller: ctrl.areaCityCtrl,
              )),
            ]),
            const SizedBox(height: 24),

            PrimaryButton(
              label: 'Add Area',
              onTap: ctrl.saveArea,
              isLoading: ctrl.isSaving.value,
              icon: Icons.add_location_alt_outlined,
            ),
          ],
        )),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ADD SLOT SHEET
// ══════════════════════════════════════════════════════════════════════════
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
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: ctrl.slotFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Add Time Slot',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Tap the button below to pick start and end times.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                fontFamily: 'Poppins',
              ),
            ),

            const SizedBox(height: 20),

            // Time picker button
            GestureDetector(
              onTap: () async {
                await ctrl.pickTimeSlot(context);

                // force rebuild bottomsheet
                (context as Element).markNeedsBuild();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),

                    const SizedBox(width: 12),

                    Text(
                      ctrl.slotLabelCtrl.text.isEmpty
                          ? 'Tap to pick time range'
                          : ctrl.slotLabelCtrl.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        color: ctrl.slotLabelCtrl.text.isEmpty
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            AppTextField(
              label: 'Label (auto-filled)',
              hint: '6:00 AM - 7:00 AM',
              controller: ctrl.slotLabelCtrl,
              validator: (v) =>
              v == null || v.trim().isEmpty
                  ? 'Please pick a time range'
                  : null,
            ),

            const SizedBox(height: 24),

            Obx(
                  () => PrimaryButton(
                label: 'Add Time Slot',
                onTap: ctrl.saveTimeSlot,
                isLoading: ctrl.isSaving.value,
                icon: Icons.schedule_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.textHint),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary,
          fontFamily: 'Poppins')),
    ]);
  }
}