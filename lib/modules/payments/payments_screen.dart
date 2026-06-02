// lib/modules/payments/payments_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_box.dart';
import 'payments_controller.dart';

class PaymentsScreen extends GetView<PaymentsController> {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: Column(
        children: [
          // Summary cards
          Obx(() => Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: "Today's Collection",
                    amount: controller.totalCollectedToday.value,
                    gradient: AppColors.gradientGreen,
                    icon: Icons.today_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'This Month',
                    amount: controller.totalCollectedThisMonth.value,
                    gradient: AppColors.gradientPurple,
                    icon: Icons.calendar_month_rounded,
                  ),
                ),
              ],
            ),
          )),

          // Method breakdown
          Obx(() {
            final breakdown = controller.methodBreakdown;
            if (breakdown.isEmpty) return const SizedBox();
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Collected By Method',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MethodChip('💵 Cash',
                          breakdown['cash'] ?? 0, AppColors.success),
                      _MethodChip('📱 UPI',
                          breakdown['upi'] ?? 0, AppColors.info),
                      _MethodChip('💳 Online',
                          breakdown['online'] ?? 0, AppColors.primary),
                    ],
                  ),
                ],
              ),
            );
          }),

          // Filter chips
          Obx(() => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.methods.map((m) {
                  final isSelected = controller.filterMethod.value == m;
                  return GestureDetector(
                    onTap: () => controller.filterMethod.value = m,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
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
                        m.toCapitalCase,
                        style: TextStyle(
                          fontSize: 12,
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
            ),
          )),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const ShimmerList(count: 6, itemHeight: 76);
              }
              final list = controller.filteredPayments;
              if (list.isEmpty) {
                return const EmptyState(
                  title: 'No Payments Found',
                  subtitle: 'Payments collected from customers appear here.',
                  icon: Icons.payments_outlined,
                );
              }
              return ListView.separated(
                padding:
                const EdgeInsets.fromLTRB(16, 4, 16, 32),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = list[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.border, width: 0.8),
                    ),
                    child: Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(p.methodEmoji,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.customerName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Poppins'),
                            ),
                            Text(
                              '${p.paymentMethod.toUpperCase()} · ${p.paidAt.formattedWithTime}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Poppins'),
                            ),
                            if (p.notes != null)
                              Text(
                                p.notes!,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textHint,
                                    fontFamily: 'Poppins'),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '+₹${p.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ]),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final List<Color> gradient;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 10),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'Poppins'),
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 11, color: Colors.white70, fontFamily: 'Poppins'),
        ),
      ]),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _MethodChip(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12, fontFamily: 'Poppins')),
      const SizedBox(height: 2),
      Text(
        '₹${amount.toStringAsFixed(0)}',
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
            fontFamily: 'Poppins'),
      ),
    ]);
  }
}
