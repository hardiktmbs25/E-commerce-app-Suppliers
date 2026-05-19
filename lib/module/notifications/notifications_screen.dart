// lib/modules/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_box.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Obx(() => controller.unreadCount.value > 0
              ? TextButton(
            onPressed: controller.markAllRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Poppins',
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
              : const SizedBox()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ShimmerList(count: 6, itemHeight: 80);
        }
        if (controller.notifications.isEmpty) {
          return const EmptyState(
            title: 'No Notifications',
            subtitle: 'Delivery alerts, payment reminders and updates will appear here.',
            icon: Icons.notifications_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: controller.notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final n = controller.notifications[i];
            return Dismissible(
              key: Key(n.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white, size: 22),
              ),
              onDismissed: (_) => controller.deleteNotification(n.id),
              child: GestureDetector(
                onTap: () => controller.markRead(n.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n.isRead
                        ? AppColors.surface
                        : AppColors.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: n.isRead
                          ? AppColors.border
                          : AppColors.primary.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(n.iconColor).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(n.icon,
                            color: Color(n.iconColor), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              if (!n.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ]),
                            const SizedBox(height: 3),
                            Text(
                              n.body,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'Poppins',
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              n.createdAt.formattedWithTime,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textHint,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}