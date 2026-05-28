// lib/modules/deliveries/extra_order/extra_order_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/inputs/app_text_field.dart';
import 'extra_order_controller.dart';

class ExtraOrderScreen extends StatelessWidget {
  const ExtraOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ExtraOrderController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Place Extra Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6), size: 18),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Extra orders are one-time deliveries added outside of the subscription schedule.',
                style: TextStyle(fontSize: 12, color: Color(0xFF8B5CF6),
                    fontFamily: 'Poppins'),
              )),
            ]),
          ),

          const SizedBox(height: 20),
          const _Label('Customer'),
          const SizedBox(height: 8),

          // Customer search
          Obx(() => Column(children: [
            AppTextField(
              controller: ctrl.customerSearchCtrl,
              hint: 'Search customer name or address...',
              prefix : Icon(Icons.search_rounded),
              onChanged: ctrl.searchCustomers, label: '',
            ),
            if (ctrl.customerSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow,
                      blurRadius: 8, offset: const Offset(0, 4))],
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
                      title: Text(c.name,
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                      subtitle: Text(c.address,
                          style: const TextStyle(fontSize: 11,
                              color: AppColors.textSecondary, fontFamily: 'Poppins'),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        radius: 18,
                        child: Text(c.name[0].toUpperCase(),
                            style: const TextStyle(fontFamily: 'Poppins',
                                color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                      onTap: () => ctrl.selectCustomer(c),
                    );
                  },
                ),
              ),
            if (ctrl.selectedCustomer.value != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                  ),
                ]),
              ),
          ])),

          const SizedBox(height: 16),
          const _Label('Service Type'),
          const SizedBox(height: 8),
          Obx(() => Wrap(
            spacing: 8, runSpacing: 8,
            children: ['milk', 'water', 'newspaper', 'tiffin', 'custom'].map((type) {
              final isSelected = ctrl.serviceType.value == type;
              return GestureDetector(
                onTap: () => ctrl.serviceType.value = type,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(type,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontFamily: 'Poppins')),
                ),
              );
            }).toList(),
          )),

          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _Label('Quantity'),
              const SizedBox(height: 8),
              AppTextField(
                label: "",
                controller: ctrl.quantityCtrl,
                hint: '1',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefix: Icon(Icons.numbers_rounded),
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _Label('Unit'),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                value: ctrl.unit.value,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border)),
                ),
                items: ['litre', 'kg', 'piece', 'packet', 'unit']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13))))
                    .toList(),
                onChanged: (v) => ctrl.unit.value = v ?? 'litre',
              )),
            ])),
          ]),

          const SizedBox(height: 16),
          const _Label('Amount (₹)'),
          const SizedBox(height: 8),
          AppTextField(
            label: "",
            controller: ctrl.amountCtrl,
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: Icon(Icons.currency_rupee_rounded),
          ),

          const SizedBox(height: 16),
          const _Label('Notes (Optional)'),
          const SizedBox(height: 8),
          AppTextField(
            label: "",
            controller: ctrl.notesCtrl,
            hint: 'Any special instructions...',
            prefix: Icon(Icons.notes_rounded),
            maxLines: 3,
          ),

          const SizedBox(height: 28),

          // Submit button
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: ctrl.isSubmitting.value ? null : ctrl.placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: ctrl.isSubmitting.value
                  ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Place Extra Order',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.white, fontFamily: 'Poppins')),
            ),
          )),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, fontFamily: 'Poppins'));
}
