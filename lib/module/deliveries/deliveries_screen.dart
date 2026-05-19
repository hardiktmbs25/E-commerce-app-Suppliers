// lib/modules/deliveries/deliveries_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/delivery_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_box.dart';
import 'deliveries_controller.dart';

class DeliveriesScreen extends StatelessWidget {
  const DeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DeliveriesController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Today\'s Deliveries'),
            Text(DateTime.now().formatted,
                style: const TextStyle(fontSize: 11,
                    color: AppColors.textSecondary, fontFamily: 'Poppins')),
          ],
        ),
        actions: [
          Obx(() => ctrl.pendingCount > 0
              ? TextButton.icon(
            onPressed: ctrl.markAllDelivered,
            icon: const Icon(Icons.done_all_rounded, size: 16),
            label: const Text('Mark All',
                style: TextStyle(fontSize: 12, fontFamily: 'Poppins')),
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
          )
              : const SizedBox()),
        ],
      ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Get.toNamed(Routes.addDeliveries),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      body: Column(children: [
        // Summary bar
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _SummaryItem('Total', '${ctrl.allDeliveries.length}',
                AppColors.primary),
            _Divider(),
            _SummaryItem('Delivered', '${ctrl.deliveredCount}',
                AppColors.success),
            _Divider(),
            _SummaryItem('Pending', '${ctrl.pendingCount}',
                AppColors.warning),
            _Divider(),
            _SummaryItem('Missed', '${ctrl.missedCount}',
                AppColors.error),
          ]),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'all', 'pending', 'delivered', 'missed', 'cancelled'
              ].map((f) {
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
                    child: Text(GetStringUtils(f).capitalize!,
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

        // List
        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value) return const ShimmerList(itemHeight: 90);
            if (ctrl.filteredDeliveries.isEmpty) {
              return EmptyState(
                title: ctrl.statusFilter.value == 'all'
                    ? 'No Deliveries Today'
                    : 'No ${GetStringUtils(ctrl.statusFilter.value).capitalize} Deliveries',
                subtitle: 'Deliveries are auto-generated from active subscriptions.',
                icon: Icons.local_shipping_outlined,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              itemCount: ctrl.filteredDeliveries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final d = ctrl.filteredDeliveries[i];
                return Slidable(
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      if (d.isPending) ...[
                        SlidableAction(
                          onPressed: (_) =>
                              ctrl.markDelivery(d, DeliveryStatus.delivered),
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          icon: Icons.check_circle_rounded,
                          label: 'Delivered',
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12)),
                        ),
                        SlidableAction(
                          onPressed: (_) =>
                              ctrl.markDelivery(d, DeliveryStatus.missed),
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          icon: Icons.cancel_rounded,
                          label: 'Missed',
                          borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12)),
                        ),
                      ],
                    ],
                  ),
                  child: Obx(() {
                    final isMarking = ctrl.markingId.value == d.id;
                    return _DeliveryCard(
                      delivery: d,
                      isMarking: isMarking,
                      onMarkDelivered: () =>
                          ctrl.markDelivery(d, DeliveryStatus.delivered),
                      onMarkMissed: () =>
                          ctrl.markDelivery(d, DeliveryStatus.missed),
                    );
                  }),
                );
              },
            );
          }),
        ),
      ]),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryModel delivery;
  final bool isMarking;
  final VoidCallback onMarkDelivered;
  final VoidCallback onMarkMissed;

  const _DeliveryCard({
    required this.delivery,
    required this.isMarking,
    required this.onMarkDelivered,
    required this.onMarkMissed,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(delivery.statusColor);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: delivery.isPending
              ? AppColors.warning.withValues(alpha: 0.3)
              : delivery.isDelivered
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: isMarking
                  ? SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: statusColor))
                  : Icon(Icons.local_shipping_rounded,
                  color: statusColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(delivery.customerName,
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary, fontFamily: 'Poppins')),
              Text(delivery.customerAddress,
                  style: const TextStyle(fontSize: 11,
                      color: AppColors.textSecondary, fontFamily: 'Poppins'),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${delivery.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary, fontFamily: 'Poppins')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(delivery.status.name.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                      color: statusColor, fontFamily: 'Poppins')),
            ),
          ]),
        ]),
        if (delivery.isPending) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _ActionBtn(
              label: '✅ Delivered',
              color: AppColors.success,
              onTap: onMarkDelivered,
            )),
            const SizedBox(width: 8),
            Expanded(child: _ActionBtn(
              label: '❌ Missed',
              color: AppColors.error,
              onTap: onMarkMissed,
            )),
          ]),
        ],
        if (delivery.deliveredAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Delivered at ${delivery.deliveredAt!.timeOnly}',
                style: const TextStyle(fontSize: 10, color: AppColors.success,
                    fontFamily: 'Poppins')),
          ),
        if (!delivery.isSynced)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Row(children: [
              Icon(Icons.cloud_off_rounded, size: 11, color: AppColors.warning),
              SizedBox(width: 4),
              Text('Pending sync', style: TextStyle(fontSize: 10,
                  color: AppColors.warning, fontFamily: 'Poppins')),
            ]),
          ),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: color, fontFamily: 'Poppins'))),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
          color: color, fontFamily: 'Poppins')),
      Text(label, style: const TextStyle(fontSize: 10,
          color: AppColors.textSecondary, fontFamily: 'Poppins')),
    ]);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 32, width: 0.8, color: AppColors.border);
  }
}