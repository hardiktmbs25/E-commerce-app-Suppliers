// lib/modules/analytics/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/shimmer_box.dart';
import 'analytics_controller.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AnalyticsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Column(children: [
              ShimmerBox(height: 160, borderRadius: 16),
              SizedBox(height: 16),
              ShimmerBox(height: 200, borderRadius: 16),
              SizedBox(height: 16),
              ShimmerBox(height: 160, borderRadius: 16),
            ]),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Revenue growth card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.gradientPurple),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('This Month Revenue',
                    style: TextStyle(fontSize: 12, color: Colors.white70,
                        fontFamily: 'Poppins')),
                const SizedBox(height: 6),
                Text('₹${ctrl.thisMonthRevenue.value.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                        color: Colors.white, fontFamily: 'Poppins')),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(
                    ctrl.revenueGrowth >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: ctrl.revenueGrowth >= 0 ? Colors.greenAccent : Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ctrl.revenueGrowth >= 0 ? '+' : ''}${ctrl.revenueGrowth.toStringAsFixed(1)}% vs last month',
                    style: TextStyle(
                      fontSize: 12, fontFamily: 'Poppins',
                      color: ctrl.revenueGrowth >= 0 ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // Bar chart (custom, no external chart lib needed)
            const Text('6-Month Revenue Trend',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, fontFamily: 'Poppins')),
            const SizedBox(height: 14),
            Container(
              height: 180,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ctrl.revenueStats.isEmpty
                  ? const Center(child: Text('No data yet',
                  style: TextStyle(color: AppColors.textHint, fontFamily: 'Poppins')))
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ctrl.revenueStats.map((stat) {
                  final maxH = 120.0;
                  final h = ctrl.maxRevenue > 0
                      ? (stat.revenue / ctrl.maxRevenue) * maxH
                      : 4.0;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('₹${(stat.revenue / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(fontSize: 9,
                              color: AppColors.textHint, fontFamily: 'Poppins')),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        width: 28,
                        height: h.clamp(4, maxH),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.gradientPurple,
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(stat.month, style: const TextStyle(fontSize: 10,
                          color: AppColors.textSecondary, fontFamily: 'Poppins')),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Delivery stats
            const Text('Delivery Performance (30 days)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, fontFamily: 'Poppins')),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _StatBox('Total', '${ctrl.totalDeliveries.value}',
                  AppColors.primary, Icons.local_shipping_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _StatBox('Delivered', '${ctrl.deliveredCount.value}',
                  AppColors.success, Icons.check_circle_outline_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _StatBox('Missed', '${ctrl.missedCount.value}',
                  AppColors.error, Icons.cancel_outlined)),
            ]),
            const SizedBox(height: 16),

            // Delivery rate gauge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Delivery Success Rate',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary, fontFamily: 'Poppins')),
                  Text('${(ctrl.deliveryRate.value * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                        color: ctrl.deliveryRate.value >= 0.9
                            ? AppColors.success
                            : ctrl.deliveryRate.value >= 0.7
                            ? AppColors.warning
                            : AppColors.error,
                      )),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ctrl.deliveryRate.value.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ctrl.deliveryRate.value >= 0.9
                          ? AppColors.success
                          : ctrl.deliveryRate.value >= 0.7
                          ? AppColors.warning
                          : AppColors.error,
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        );
      }),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatBox(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
            color: color, fontFamily: 'Poppins')),
        Text(label, style: const TextStyle(fontSize: 10,
            color: AppColors.textSecondary, fontFamily: 'Poppins')),
      ]),
    );
  }
}