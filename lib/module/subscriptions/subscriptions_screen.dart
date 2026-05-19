// lib/modules/subscriptions/subscriptions_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_box.dart';
import '../../widgets/dialogs/confirm_dialog.dart';
import 'subscriptions_controller.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SubscriptionsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      body: Column(children: [
        // Summary bar
        Obx(() => Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.gradientGreen),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryChip('Active', '${ctrl.activeCount}'),
              _SummaryChip('Paused', '${ctrl.pausedCount}'),
              _SummaryChip('Monthly Rev',
                  '₹${ctrl.totalMonthlyRevenue.toStringAsFixed(0)}'),
            ],
          ),
        )),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'active', 'paused', 'cancelled'].map((f) {
                final isSelected = ctrl.statusFilter.value == f;
                return GestureDetector(
                  onTap: () => ctrl.statusFilter.value = f,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(f.capitalize!,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontFamily: 'Poppins')),
                  ),
                );
              }).toList(),
            ),
          )),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value) return const ShimmerList();
            if (ctrl.filteredSubs.isEmpty) {
              return const EmptyState(
                title: 'No Subscriptions',
                subtitle: 'Add subscriptions from the customer detail screen.',
                icon: Icons.subscriptions_outlined,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: ctrl.filteredSubs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final sub = ctrl.filteredSubs[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(sub.customerName,
                            style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Poppins'))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sub.isActive
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(sub.statusStr.toUpperCase(),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                                  color: sub.isActive ? AppColors.success : AppColors.warning,
                                  fontFamily: 'Poppins')),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        Text('${sub.quantity} ${sub.unit} • ${sub.frequencyLabel}',
                            style: const TextStyle(fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'Poppins')),
                        const Spacer(),
                        Text('₹${sub.pricePerDelivery.toStringAsFixed(0)}/delivery',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                color: AppColors.primary, fontFamily: 'Poppins')),
                      ]),
                      Text('Slot: ${sub.deliverySlot}',
                          style: const TextStyle(fontSize: 11,
                              color: AppColors.textHint, fontFamily: 'Poppins')),
                      Text('Est. ₹${sub.estimatedMonthlyRevenue.toStringAsFixed(0)}/month',
                          style: const TextStyle(fontSize: 11,
                              color: AppColors.textHint, fontFamily: 'Poppins')),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () => ctrl.togglePause(sub),
                          icon: Icon(sub.isActive
                              ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 16),
                          label: Text(sub.isActive ? 'Pause' : 'Resume',
                              style: const TextStyle(fontSize: 12, fontFamily: 'Poppins')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: sub.isActive
                                ? AppColors.warning : AppColors.success,
                            side: BorderSide(color: sub.isActive
                                ? AppColors.warning : AppColors.success),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showConfirmDialog(
                              title: 'Cancel Subscription',
                              message: 'Cancel ${sub.customerName}\'s subscription?',
                              confirmLabel: 'Cancel Sub',
                              isDangerous: true,
                            );
                            if (confirm == true) ctrl.cancelSubscription(sub);
                          },
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Cancel',
                              style: TextStyle(fontSize: 12, fontFamily: 'Poppins')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        )),
                      ]),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(Routes.addSubscription),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  const _SummaryChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
          color: Colors.white, fontFamily: 'Poppins')),
      Text(label, style: const TextStyle(fontSize: 10,
          color: Colors.white70, fontFamily: 'Poppins')),
    ]);
  }
}