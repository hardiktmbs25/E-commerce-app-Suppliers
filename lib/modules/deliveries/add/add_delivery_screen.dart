// lib/modules/deliveries/add/add_delivery_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/subscription_model.dart';
import 'add_delivery_controller.dart';

class AddDeliveryScreen extends StatelessWidget {
  const AddDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddDeliveryController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Delivery'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Obx(() => _TypeTabBar(
            selected: ctrl.deliveryType.value,
            onChanged: (t) => ctrl.deliveryType.value = t,
          )),
        ),
      ),
      body: Obx(() => ctrl.deliveryType.value == AddDeliveryType.manual
          ? _ManualForm(ctrl: ctrl)
          : _SubscriptionForm(ctrl: ctrl)),
    );
  }
}

// ── Tab bar ────────────────────────────────────────────────────────────────
class _TypeTabBar extends StatelessWidget {
  final AddDeliveryType selected;
  final ValueChanged<AddDeliveryType> onChanged;
  const _TypeTabBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        _Tab(
          label: '📦 Manual Delivery',
          isSelected: selected == AddDeliveryType.manual,
          onTap: () => onChanged(AddDeliveryType.manual),
        ),
        _Tab(
          label: '🔄 From Subscription',
          isSelected: selected == AddDeliveryType.fromSubscription,
          onTap: () => onChanged(AddDeliveryType.fromSubscription),
        ),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [const BoxShadow(color: AppColors.cardShadow,
                blurRadius: 6, offset: Offset(0, 2))]
                : [],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              )),
        ),
      ),
    );
  }
}

// ── Customer Picker (shared) ───────────────────────────────────────────────
class _CustomerPicker extends StatelessWidget {
  final AddDeliveryController ctrl;
  const _CustomerPicker({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Label('Customer *'),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl.customerSearchCtrl,
        onChanged: ctrl.onCustomerSearch,
        enabled: ctrl.selectedCustomer.value == null,
        decoration: InputDecoration(
          hintText: 'Search by name or address...',
          hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
              color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
        ),
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
      ),

      // Suggestions dropdown
      if (ctrl.customerSuggestions.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: const [BoxShadow(color: AppColors.cardShadow,
                blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ctrl.customerSuggestions.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 0, color: AppColors.divider),
            itemBuilder: (_, i) {
              final c = ctrl.customerSuggestions[i];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(c.name[0].toUpperCase(),
                      style: const TextStyle(color: AppColors.primary,
                          fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                ),
                title: Text(c.name,
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                subtitle: Text(c.address,
                    style: const TextStyle(fontSize: 11,
                        color: AppColors.textSecondary, fontFamily: 'Poppins'),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => ctrl.selectCustomerFromSuggestion(c),
              );
            },
          ),
        ),

      // Selected customer chip
      if (ctrl.selectedCustomer.value != null)
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.success.withValues(alpha: 0.15),
              child: Text(ctrl.selectedCustomer.value!.name[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.success,
                      fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ctrl.selectedCustomer.value!.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary, fontFamily: 'Poppins')),
                  Text(ctrl.selectedCustomer.value!.address,
                      style: const TextStyle(fontSize: 11,
                          color: AppColors.textSecondary, fontFamily: 'Poppins'),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
            GestureDetector(
              onTap: ctrl.clearCustomer,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 14,
                    color: AppColors.error),
              ),
            ),
          ]),
        ),
    ]));
  }
}

// ── Date + Slot picker (shared) ────────────────────────────────────────────
class _DateSlotRow extends StatelessWidget {
  final AddDeliveryController ctrl;
  const _DateSlotRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Label('Delivery Date *'),
        const SizedBox(height: 8),
        Obx(() => GestureDetector(
          onTap: ctrl.pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 16,
                  color: AppColors.primary),
              const SizedBox(width: 8),
              Text(ctrl.scheduledDate.value.formatted,
                  style: const TextStyle(fontSize: 13, fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ]),
          ),
        )),
      ])),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Label('Delivery Slot'),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl.slotCtrl,
          decoration: InputDecoration(
            hintText: '07:00 AM',
            hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            prefixIcon: const Icon(Icons.access_time_rounded, size: 18),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
      ])),
    ]);
  }
}

// ── Qty + Unit row (shared) ────────────────────────────────────────────────
class _QtyUnitRow extends StatelessWidget {
  final AddDeliveryController ctrl;
  const _QtyUnitRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Label('Quantity *'),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl.quantityCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '1',
            prefixIcon: const Icon(Icons.numbers_rounded, size: 18),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
      ])),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _Label('Unit'),
        const SizedBox(height: 8),
        Obx(() => DropdownButtonFormField<String>(
          value: ctrl.unit.value,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          items: ['litre', 'kg', 'piece', 'packet', 'unit', 'copy', 'can', 'box']
              .map((u) => DropdownMenuItem(value: u,
              child: Text(u, style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 13))))
              .toList(),
          onChanged: (v) => ctrl.unit.value = v ?? 'litre',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
              color: AppColors.textPrimary),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        )),
      ])),
    ]);
  }
}

// ── Submit button (shared) ─────────────────────────────────────────────────
class _SubmitButton extends StatelessWidget {
  final AddDeliveryController ctrl;
  const _SubmitButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: ctrl.isSubmitting.value ? null : ctrl.submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: ctrl.isSubmitting.value
            ? const SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Text('Add Delivery',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: Colors.white, fontFamily: 'Poppins')),
      ),
    ));
  }
}

// ══════════════════════════════════════════════════════════════════════════
// MANUAL FORM
// ══════════════════════════════════════════════════════════════════════════
class _ManualForm extends StatelessWidget {
  final AddDeliveryController ctrl;
  const _ManualForm({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Use this for one-time deliveries not linked to any subscription.',
              style: TextStyle(fontSize: 12, color: AppColors.info,
                  fontFamily: 'Poppins'),
            )),
          ]),
        ),
        const SizedBox(height: 20),

        // Customer
        _CustomerPicker(ctrl: ctrl),
        const SizedBox(height: 16),

        // Service type chips
        const _Label('Service Type *'),
        const SizedBox(height: 8),
        Obx(() => Wrap(
          spacing: 8, runSpacing: 8,
          children: ['milk', 'water', 'newspaper', 'tiffin', 'custom']
              .map((t) {
            final isSel = ctrl.serviceType.value == t;
            return GestureDetector(
              onTap: () => ctrl.serviceType.value = t,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: isSel ? AppColors.primary : AppColors.border),
                ),
                child: Text(t.toCapitalCase,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: isSel ? Colors.white : AppColors.textSecondary)),
              ),
            );
          }).toList(),
        )),
        const SizedBox(height: 16),

        // Qty + Unit
        _QtyUnitRow(ctrl: ctrl),
        const SizedBox(height: 16),

        // Amount
        const _Label('Amount (₹) *'),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl.amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        const SizedBox(height: 16),

        // Date + slot
        _DateSlotRow(ctrl: ctrl),
        const SizedBox(height: 16),

        // Notes
        const _Label('Notes (optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl.notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any special instructions...',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        const SizedBox(height: 28),

        _SubmitButton(ctrl: ctrl),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// FROM SUBSCRIPTION FORM
// ══════════════════════════════════════════════════════════════════════════
class _SubscriptionForm extends StatelessWidget {
  final AddDeliveryController ctrl;
  const _SubscriptionForm({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
          ),
          child: const Row(children: [
            Icon(Icons.repeat_rounded, color: Color(0xFF8B5CF6), size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Add a delivery for a specific date based on an existing subscription — '
                  'useful for missed days or manual backdating.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8B5CF6),
                  fontFamily: 'Poppins'),
            )),
          ]),
        ),
        const SizedBox(height: 20),

        // Customer picker
        _CustomerPicker(ctrl: ctrl),
        const SizedBox(height: 16),

        // Subscription selector
        const _Label('Select Subscription *'),
        const SizedBox(height: 8),
        Obx(() {
          if (ctrl.selectedCustomer.value == null) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(children: [
                Icon(Icons.arrow_upward_rounded, size: 14,
                    color: AppColors.textHint),
                SizedBox(width: 8),
                Text('Select a customer first to see their subscriptions',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint,
                        fontFamily: 'Poppins')),
              ]),
            );
          }
          if (ctrl.customerSubs.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded, size: 14,
                    color: AppColors.warning),
                SizedBox(width: 8),
                Text('No active subscriptions found for this customer.',
                    style: TextStyle(fontSize: 12, color: AppColors.warning,
                        fontFamily: 'Poppins')),
              ]),
            );
          }
          return Column(children: ctrl.customerSubs
              .map((sub) => _SubscriptionCard(
            sub: sub,
            isSelected: ctrl.selectedSubscription.value?.id == sub.id,
            onTap: () => ctrl.selectSubscription(sub),
          ))
              .toList());
        }),
        const SizedBox(height: 16),

        // Date + slot
        _DateSlotRow(ctrl: ctrl),
        const SizedBox(height: 16),

        // Qty + Unit (pre-filled from sub but editable)
        _QtyUnitRow(ctrl: ctrl),
        const SizedBox(height: 16),

        // Amount (pre-filled)
        const _Label('Amount (₹) *'),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl.amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        const SizedBox(height: 16),

        // Notes
        const _Label('Notes (optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl.notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g., Replacement for missed delivery on...',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        const SizedBox(height: 28),

        _SubmitButton(ctrl: ctrl),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ── Subscription card ──────────────────────────────────────────────────────
class _SubscriptionCard extends StatelessWidget {
  final SubscriptionModel sub;
  final bool isSelected;
  final VoidCallback onTap;
  const _SubscriptionCard(
      {required this.sub, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              sub.serviceTypeStr == 'milk'
                  ? Icons.water_drop_rounded
                  : sub.serviceTypeStr == 'newspaper'
                  ? Icons.newspaper_rounded
                  : sub.serviceTypeStr == 'tiffin'
                  ? Icons.lunch_dining_rounded
                  : Icons.inventory_2_rounded,
              color: AppColors.primary, size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.serviceTypeStr.toCapitalCase,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary, fontFamily: 'Poppins')),
                Text('${sub.quantity} ${sub.unit} · ${sub.frequencyLabel} · '
                    '₹${sub.pricePerDelivery.toStringAsFixed(0)}/delivery',
                    style: const TextStyle(fontSize: 11,
                        color: AppColors.textSecondary, fontFamily: 'Poppins')),
              ])),
          if (isSelected)
            Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
            )
          else
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Shared label ───────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary, fontFamily: 'Poppins'));
}
