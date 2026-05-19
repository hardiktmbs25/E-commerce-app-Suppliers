// lib/modules/billing/billing_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/invoice_model.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/shimmer_box.dart';
import 'billing_controller.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BillingController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Billing & Payments')),
      body: Column(children: [
        // Pending amount banner
        Obx(() => Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.gradientOrange),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Pending',
                  style: TextStyle(fontSize: 12, color: Colors.white70,
                      fontFamily: 'Poppins')),
              Text('₹${ctrl.totalPendingAmount.value.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                      color: Colors.white, fontFamily: 'Poppins')),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${ctrl.pendingInvoices.length} invoices',
                  style: const TextStyle(fontSize: 12,
                      color: Colors.white70, fontFamily: 'Poppins')),
              const Text('unpaid', style: TextStyle(fontSize: 11,
                  color: Colors.white60, fontFamily: 'Poppins')),
            ]),
          ]),
        )),

        // Generate bill section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Generate Monthly Bill',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary, fontFamily: 'Poppins')),
              const SizedBox(height: 10),
              Obx(() => DropdownButtonFormField<String>(
                value: ctrl.selectedCustomer.value?.id,
                decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                hint: const Text('Select customer',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                items: ctrl.customers.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                )).toList(),
                onChanged: (id) {
                  ctrl.selectedCustomer.value =
                      ctrl.customers.firstWhereOrNull((c) => c.id == id);
                },
              )),
              const SizedBox(height: 10),
              Obx(() => PrimaryButton(
                label: 'Generate Bill',
                onTap: ctrl.selectedCustomer.value != null
                    ? () => ctrl.generateBillForCustomer(ctrl.selectedCustomer.value!)
                    : null,
                isLoading: ctrl.isGenerating.value,
                color: AppColors.secondary,
                icon: Icons.receipt_long_rounded,
              )),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Pending invoices list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Pending Invoices',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, fontFamily: 'Poppins')),
            Obx(() => Text('${ctrl.pendingInvoices.length} total',
                style: const TextStyle(fontSize: 12,
                    color: AppColors.textSecondary, fontFamily: 'Poppins'))),
          ]),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value) return const ShimmerList(itemHeight: 100);
            if (ctrl.pendingInvoices.isEmpty) {
              return const EmptyState(
                title: 'All Payments Cleared 🎉',
                subtitle: 'No pending invoices. Generate bills from the section above.',
                icon: Icons.check_circle_outline_rounded,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: ctrl.pendingInvoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final inv = ctrl.pendingInvoices[i];
                return _InvoiceTile(
                  invoice: inv,
                  onRecordPayment: () =>
                      _showPaymentSheet(context, ctrl, inv),
                );
              },
            );
          }),
        ),
      ]),
    );
  }

  void _showPaymentSheet(
      BuildContext context, BillingController ctrl, InvoiceModel inv) {
    final amountCtrl = TextEditingController(
        text: inv.pendingAmount.toStringAsFixed(2));
    String method = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20, right: 20, top: 20,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Record Payment — ${inv.customerName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 16),
          TextField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          StatefulBuilder(builder: (_, setState) => Column(children: [
            const Text('Payment Method', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            Row(children: ['cash', 'upi', 'online'].map((m) {
              final isSelected = method == m;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => method = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Center(child: Text(m.toUpperCase(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontFamily: 'Poppins'))),
                ),
              ));
            }).toList()),
          ])),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Record Payment',
            color: AppColors.success,
            onTap: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;
              Get.back();
              ctrl.recordPayment(inv, amount, method);
            },
          ),
        ]),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onRecordPayment;
  const _InvoiceTile({required this.invoice, required this.onRecordPayment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: invoice.isOverdue
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(invoice.customerName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, fontFamily: 'Poppins'))),
          if (invoice.isOverdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text('OVERDUE', style: TextStyle(fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.error, fontFamily: 'Poppins')),
            ),
        ]),
        const SizedBox(height: 4),
        Text('${invoice.monthName} ${invoice.year} • ${invoice.invoiceNumber}',
            style: const TextStyle(fontSize: 11,
                color: AppColors.textSecondary, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Total', style: TextStyle(fontSize: 10,
                color: AppColors.textHint, fontFamily: 'Poppins')),
            Text('₹${invoice.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, fontFamily: 'Poppins')),
          ]),
          const SizedBox(width: 20),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pending', style: TextStyle(fontSize: 10,
                color: AppColors.textHint, fontFamily: 'Poppins')),
            Text('₹${invoice.pendingAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                    color: AppColors.error, fontFamily: 'Poppins')),
          ]),
          const Spacer(),
          ElevatedButton(
            onPressed: onRecordPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Collect',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: Colors.white, fontFamily: 'Poppins')),
          ),
        ]),
      ]),
    );
  }
}