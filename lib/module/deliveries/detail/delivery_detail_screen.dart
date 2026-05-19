// lib/module/deliveries/detail/delivery_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/delivery_model.dart';
import 'delivery_detail_controller.dart';

class DeliveryDetailScreen extends StatelessWidget {
  const DeliveryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DeliveryDetailController>();
    return Obx(() {
      final d = ctrl.delivery.value;
      if (d == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      final statusColor = Color(d.statusColor);
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Delivery Detail'),
          actions: [
            if (d.isPending)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delivered') ctrl.markDelivery(DeliveryStatus.delivered);
                  if (v == 'missed') ctrl.showNotesDialog(DeliveryStatus.missed);
                  if (v == 'cancelled') ctrl.showNotesDialog(DeliveryStatus.cancelled);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delivered', child: Text('✅ Mark Delivered')),
                  const PopupMenuItem(value: 'missed', child: Text('❌ Mark Missed')),
                  const PopupMenuItem(value: 'cancelled', child: Text('🚫 Cancel Delivery')),
                ],
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    d.isDelivered ? Icons.check_circle_rounded
                        : d.isMissed ? Icons.cancel_rounded
                        : Icons.local_shipping_rounded,
                    color: statusColor, size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.status.name.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                          color: statusColor, fontFamily: 'Poppins',
                          letterSpacing: 1)),
                  Text(d.isDelivered && d.deliveredAt != null
                      ? 'Delivered at ${d.deliveredAt!.timeOnly}'
                      : 'Scheduled: ${d.scheduledDate.timeOnly}',
                      style: const TextStyle(fontSize: 12,
                          color: AppColors.textSecondary, fontFamily: 'Poppins')),
                ])),
                if (!d.isSynced)
                  const Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 18),
              ]),
            ),

            const SizedBox(height: 16),

            // Customer info
            _SectionCard(
              title: 'Customer',
              icon: Icons.person_rounded,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _InfoRow('Name', d.customerName),
                _InfoRow('Address', d.customerAddress),
                _InfoRow('Customer ID', d.customerId),
              ]),
            ),

            const SizedBox(height: 12),

            // Delivery info
            _SectionCard(
              title: 'Delivery Info',
              icon: Icons.local_shipping_outlined,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _InfoRow('Service', d.serviceTypeStr.titleCase),
                _InfoRow('Quantity', '${d.quantity} ${d.unit}'),
                _InfoRow('Amount', '₹${d.amount.toStringAsFixed(2)}'),
                _InfoRow('Slot', d.deliverySlot),
                _InfoRow('Route Order', '#${d.routeOrder + 1}'),
                if (d.isExtraOrder)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                    ),
                    child: const Text('⚡ Extra Order',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: Color(0xFF8B5CF6), fontFamily: 'Poppins')),
                  ),
              ]),
            ),

            const SizedBox(height: 12),

            // Notes
            _SectionCard(
              title: 'Notes',
              icon: Icons.notes_rounded,
              child: d.notes != null && d.notes!.isNotEmpty
                  ? Text(d.notes!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary,
                      fontFamily: 'Poppins'))
                  : const Text('No notes added.',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint,
                      fontFamily: 'Poppins')),
            ),

            const SizedBox(height: 12),

            // Timestamps
            _SectionCard(
              title: 'Timestamps',
              icon: Icons.access_time_rounded,
              child: Column(children: [
                _InfoRow('Scheduled', d.scheduledDate.formattedWithTime),
                if (d.deliveredAt != null)
                  _InfoRow('Delivered At', d.deliveredAt!.formattedWithTime),
                _InfoRow('Created', d.createdAt.formattedWithTime),
                _InfoRow('Updated', d.updatedAt.formattedWithTime),
              ]),
            ),

            const SizedBox(height: 20),

            // Action buttons for pending deliveries
            if (d.isPending) ...[
              Row(children: [
                Expanded(child: _BigActionBtn(
                  label: 'Mark Delivered',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  onTap: () => ctrl.markDelivery(DeliveryStatus.delivered),
                  isLoading: ctrl.isMarking.value,
                )),
                const SizedBox(width: 10),
                Expanded(child: _BigActionBtn(
                  label: 'Mark Missed',
                  icon: Icons.cancel_rounded,
                  color: AppColors.error,
                  onTap: () => ctrl.showNotesDialog(DeliveryStatus.missed),
                  isLoading: false,
                )),
              ]),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: _BigActionBtn(
                label: 'Add Notes',
                icon: Icons.edit_note_rounded,
                color: AppColors.info,
                onTap: ctrl.showAddNotesDialog,
                isLoading: false,
              )),
            ],

            // Re-open missed delivery
            if (d.isMissed)
              SizedBox(width: double.infinity, child: _BigActionBtn(
                label: 'Re-open as Pending',
                icon: Icons.replay_rounded,
                color: AppColors.warning,
                onTap: () => ctrl.markDelivery(DeliveryStatus.pending),
                isLoading: ctrl.isMarking.value,
              )),

            const SizedBox(height: 32),
          ]),
        ),
      );
    });
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: AppColors.textSecondary, fontFamily: 'Poppins',
              letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 10),
        const Divider(color: AppColors.divider, height: 0),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary,
                  fontFamily: 'Poppins')),
        ),
        Expanded(child: Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, fontFamily: 'Poppins'))),
      ]),
    );
  }
}

class _BigActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;
  const _BigActionBtn({required this.label, required this.icon,
    required this.color, required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isLoading)
            SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color))
          else
            Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: color, fontFamily: 'Poppins')),
        ]),
      ),
    );
  }
}