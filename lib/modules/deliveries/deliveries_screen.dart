// lib/modules/deliveries/deliveries_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/delivery_model.dart';
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
            Text(
              DateTime.now().formatted,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        actions: [
          // History button
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Delivery History',
            onPressed: ctrl.goToHistory,
          ),
          // Mark All button
          Obx(
                () => ctrl.pendingCount > 0
                ? TextButton.icon(
              onPressed: ctrl.markAllDelivered,
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text(
                'Mark All',
                style: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.success,
              ),
            )
                : const SizedBox(),
          ),
        ],
      ),
      floatingActionButton: Obx(() => FloatingActionButton.extended(
        heroTag: 'fab_deliveries',
        onPressed: ctrl.isGenerating.value ? null : () => _showSlotPicker(context, ctrl),
        backgroundColor: ctrl.isGenerating.value ? AppColors.border : AppColors.primary,
        icon: ctrl.isGenerating.value
            ? const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          ctrl.isGenerating.value ? 'Generating...' : 'Generate',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      )),
      body: Column(
        children: [
          // Summary bar
          Obx(
                () => Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    'Total',
                    '${ctrl.allDeliveries.length}',
                    AppColors.primary,
                  ),
                  _Divider(),
                  _SummaryItem(
                    'Delivered',
                    '${ctrl.deliveredCount}',
                    AppColors.success,
                  ),
                  _Divider(),
                  _SummaryItem(
                    'Pending',
                    '${ctrl.pendingCount}',
                    AppColors.warning,
                  ),
                  _Divider(),
                  _SummaryItem(
                    'Missed',
                    '${ctrl.missedCount}',
                    AppColors.error,
                  ),
                ],
              ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: ctrl.searchCtrl,
              onChanged: ctrl.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by customer or address...',
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: Obx(
                      () => ctrl.searchQuery.value.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: ctrl.clearSearch,
                  )
                      : const SizedBox(),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Obx(
                  () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                  [
                    'all',
                    'pending',
                    'delivered',
                    'missed',
                    'cancelled',
                  ].map((f) {
                    final isSelected = ctrl.statusFilter.value == f;
                    return GestureDetector(
                      onTap: () => ctrl.statusFilter.value = f,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          f.toCapitalCase,
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
            ),
          ),
          const SizedBox(height: 6),

          // Time-slot filter chips
          Obx(() {
            if (ctrl.availableTimeSlots.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SlotChip(
                      label: 'All Slots',
                      isSelected: ctrl.slotFilter.value.isEmpty,
                      onTap: ctrl.clearSlotFilter,
                      icon: Icons.access_time_rounded,
                    ),
                    ...ctrl.availableTimeSlots.map((slot) {
                      final isSelected = ctrl.slotFilter.value == slot.startTime;
                      return _SlotChip(
                        label: slot.label,
                        isSelected: isSelected,
                        onTap: () => ctrl.slotFilter.value = slot.startTime,
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value)
                return const ShimmerList(itemHeight: 90);
              if (ctrl.filteredDeliveries.isEmpty) {
                return RefreshIndicator(
                  onRefresh: ctrl.refresh,
                  color: AppColors.primary,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: EmptyState(
                        title: ctrl.searchQuery.value.isNotEmpty
                            ? 'No Results Found'
                            : ctrl.statusFilter.value == 'all'
                            ? 'No Deliveries Today'
                            : 'No ${ctrl.statusFilter.value.toCapitalCase} Deliveries',
                        subtitle: ctrl.searchQuery.value.isNotEmpty
                            ? 'Try a different search term.'
                            : 'Deliveries are auto-generated from active subscriptions.',
                        icon: Icons.local_shipping_outlined,
                        actionLabel: ctrl.searchQuery.value.isNotEmpty
                            ? 'Clear Search'
                            : null,
                        onAction: ctrl.searchQuery.value.isNotEmpty
                            ? ctrl.clearSearch
                            : null,
                      ),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: ctrl.refresh,
                color: AppColors.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
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
                              onPressed: (_) => ctrl.markDelivery(
                                d,
                                DeliveryStatus.delivered,
                              ),
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              icon: Icons.check_circle_rounded,
                              label: 'Delivered',
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            SlidableAction(
                              onPressed: (_) => ctrl.showMarkWithNotesDialog(
                                d,
                                DeliveryStatus.missed,
                              ),
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              icon: Icons.cancel_rounded,
                              label: 'Missed',
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
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
                          onMarkMissed: () => ctrl.showMarkWithNotesDialog(
                            d,
                            DeliveryStatus.missed,
                          ),
                          onTap: () => ctrl.goToDetail(d),
                        );
                      }),
                    );
                  },
                ),
              ); // closes RefreshIndicator
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Slot Picker Bottom Sheet
  // ─────────────────────────────────────────────────────────────

  void _showSlotPicker(BuildContext context, DeliveriesController ctrl) {
    if (ctrl.availableTimeSlots.isEmpty) {
      Get.snackbar(
        'No Time Slots',
        'Please add time slots in Profile → Time Slots first.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
      return;
    }

    final selected = <String>{}.obs;

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      Obx(() => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text(
              'Select Time Slot(s)',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Deliveries will be created for all active subscriptions matching the selected slot.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),

            // Slot tiles
            ...ctrl.availableTimeSlots.map((slot) {
              final isSelected = selected.contains(slot.startTime);
              return GestureDetector(
                onTap: () {
                  if (isSelected) {
                    selected.remove(slot.startTime);
                  } else {
                    selected.add(slot.startTime);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: isSelected ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              slot.startTime,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? AppColors.primary : AppColors.border,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selected.isEmpty
                    ? null
                    : () async {
                  Get.back();
                  await ctrl.generateForSlots(selected.toList());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  selected.isEmpty
                      ? 'Select a slot to continue'
                      : 'Generate for ${selected.length} slot${selected.length > 1 ? "s" : ""}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryModel delivery;
  final bool isMarking;
  final VoidCallback onMarkDelivered;
  final VoidCallback onMarkMissed;
  final VoidCallback onTap;

  const _DeliveryCard({
    required this.delivery,
    required this.isMarking,
    required this.onMarkDelivered,
    required this.onMarkMissed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(delivery.statusColor);
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isMarking
                        ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: statusColor,
                      ),
                    )
                        : Icon(
                      Icons.local_shipping_rounded,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              delivery.customerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          if (delivery.isExtraOrder)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Text(
                                '⚡ Extra',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF8B5CF6),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        delivery.customerAddress,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${delivery.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        delivery.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ],
            ),
            // Notes preview
            if (delivery.notes != null && delivery.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notes_rounded,
                      size: 12,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        delivery.notes!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (delivery.isPending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: '✅ Delivered',
                      color: AppColors.success,
                      onTap: onMarkDelivered,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      label: '❌ Missed',
                      color: AppColors.error,
                      onTap: onMarkMissed,
                    ),
                  ),
                ],
              ),
            ],
            if (delivery.deliveredAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Delivered at ${delivery.deliveredAt!.timeOnly}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.success,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            if (!delivery.isSynced)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 11,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Pending sync',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.warning,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

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
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ),
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
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 32, width: 0.8, color: AppColors.border);
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _SlotChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.schedule_rounded,
              size: 13,
              color: isSelected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}