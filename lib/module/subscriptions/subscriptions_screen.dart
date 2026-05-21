// lib/module/subscriptions/subscriptions_screen.dart
//
// CHANGES:
//  • List cards updated to show DeliveryFrequency label and effectiveSlots
//  • Service emoji shown on card
//  • Card actions (pause/cancel) preserved
//  • Improved empty state

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/service_constants.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(Routes.globalPlans),
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Manage Plans & Areas',
          ),
        ],
      ),
      body: Column(children: [
        // ── Summary bar ──────────────────────────────────────────────────
        Obx(() => Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.gradientGreen),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryChip(
                  label: 'Active',
                  value: '${ctrl.activeCount}',
                  icon: Icons.check_circle_rounded),
              _SummaryDivider(),
              _SummaryChip(
                  label: 'Paused',
                  value: '${ctrl.pausedCount}',
                  icon: Icons.pause_circle_rounded),
              _SummaryDivider(),
              _SummaryChip(
                  label: 'Monthly',
                  value: '₹${ctrl.totalMonthlyRevenue.toStringAsFixed(0)}',
                  icon: Icons.currency_rupee_rounded),
            ],
          ),
        )),

        const SizedBox(height: 12),

        // ── Filter chips ─────────────────────────────────────────────────
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border),
                    ),
                    child: Text(
                      f.capitalize!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          )),
        ),

        const SizedBox(height: 8),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value) return const ShimmerList();
            if (ctrl.filteredSubs.isEmpty) {
              return const EmptyState(
                title: 'No Subscriptions',
                subtitle:
                'Tap the + button to add a new subscription.',
                icon: Icons.subscriptions_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: ctrl.filteredSubs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final sub = ctrl.filteredSubs[i];
                final serviceColor =
                ServiceConstants.colorFor(sub.serviceTypeStr);
                final serviceIcon =
                ServiceConstants.iconFor(sub.serviceTypeStr);

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.border, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      // ── Card header ────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service icon circle
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: serviceColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(serviceIcon,
                                  size: 22, color: serviceColor),
                            ),
                            const SizedBox(width: 12),
                            // Customer name + service
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sub.customerName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ServiceConstants
                                        .labelFor(sub.serviceTypeStr),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: serviceColor,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Status badge
                            _StatusBadge(isActive: sub.isActive,
                                label: sub.statusStr),
                          ],
                        ),
                      ),

                      // ── Info row ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        child: Row(children: [
                          _InfoChip(
                            icon: Icons.scale_rounded,
                            label:
                            '${sub.quantity} ${sub.unit}',
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.repeat_rounded,
                            label: sub.frequencyLabel,
                          ),
                          const Spacer(),
                          Text(
                            '₹${sub.pricePerDelivery.toStringAsFixed(0)}/delivery',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ]),
                      ),

                      // ── Time slots ─────────────────────────────────
                      if (sub.effectiveSlots.isNotEmpty)
                        Padding(
                          padding:
                          const EdgeInsets.fromLTRB(14, 0, 14, 10),
                          child: Row(children: [
                            const Icon(Icons.schedule_rounded,
                                size: 14,
                                color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              sub.effectiveSlots.join(' · '),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ]),
                        ),

                      // ── Monthly est ────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        child: Row(children: [
                          const Icon(Icons.trending_up_rounded,
                              size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            'Est. ₹${sub.estimatedMonthlyRevenue.toStringAsFixed(0)}/month',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ]),
                      ),

                      // ── Actions divider ────────────────────────────
                      const Divider(
                          height: 1, color: AppColors.divider),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Row(children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () =>
                                  ctrl.togglePause(sub),
                              icon: Icon(
                                sub.isActive
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 18,
                              ),
                              label: Text(
                                  sub.isActive ? 'Pause' : 'Resume'),
                              style: TextButton.styleFrom(
                                foregroundColor: sub.isActive
                                    ? AppColors.warning
                                    : AppColors.success,
                                textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins'),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                              ),
                            ),
                          ),
                          Container(
                              width: 1,
                              height: 24,
                              color: AppColors.divider),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () async {
                                final ok = await showConfirmDialog(
                                  title: 'Cancel Subscription',
                                  message:
                                  "Cancel ${sub.customerName}'s subscription?",
                                  confirmLabel: 'Yes, Cancel',
                                  isDangerous: true,
                                );
                                if (ok == true) {
                                  ctrl.cancelSubscription(sub);
                                }
                              },
                              icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 18),
                              label: const Text('Cancel'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins'),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ]),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(Routes.addSubscription),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

// ── Helper sub-widgets ───────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _SummaryChip(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: Colors.white70),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Poppins')),
      Text(label,
          style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontFamily: 'Poppins')),
    ],
  );
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 40, color: Colors.white24);
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final String label;
  const _StatusBadge({required this.isActive, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: (isActive ? AppColors.success : AppColors.warning)
          .withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: isActive ? AppColors.success : AppColors.warning,
        fontFamily: 'Poppins',
      ),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.textSecondary),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500)),
    ]),
  );
}