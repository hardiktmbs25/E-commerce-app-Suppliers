// lib/modules/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import '../../routes/app_routes.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_box.dart';

import '../billing/billing_screen.dart';
import '../customers/customers_screen.dart';
import '../deliveries/deliveries_screen.dart';
import '../profile/profile_screen.dart';

import 'dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
            () => IndexedStack(
          index: controller.currentTabIndex.value,
          children: const [
            _HomeTab(),
            CustomersScreen(),
            DeliveriesScreen(),
            BillingScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
            () => _BottomNav(
          currentIndex: controller.currentTabIndex.value,
          onTap: controller.changeTab,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom Nav
// ─────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Home',
                index: 0,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
                label: 'Customers',
                index: 1,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.local_shipping_outlined,
                activeIcon: Icons.local_shipping_rounded,
                label: 'Deliveries',
                index: 2,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Billing',
                index: 3,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                index: 4,
                current: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color:
              isActive ? AppColors.primary : AppColors.textHint,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                isActive ? FontWeight.w700 : FontWeight.w500,
                color:
                isActive ? AppColors.primary : AppColors.textHint,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Home Tab
// ─────────────────────────────────────────────────────────────

class _HomeTab extends GetView<DashboardController> {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final connectivity = Get.find<ConnectivityService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.refresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ─────────────────────────────
            // Offline Banner
            // ─────────────────────────────

            SliverToBoxAdapter(
              child: Obx(
                    () => !connectivity.isOnline.value
                    ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  color: AppColors.warning,
                  child: const Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Offline — changes will sync when connected',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                )
                    : const SizedBox(),
              ),
            ),

            // ─────────────────────────────
            // Header
            // ─────────────────────────────

            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 16,
                  20,
                  24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.gradientPurple,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.greeting,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(
                                  alpha: 0.8,
                                ),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 2),

                            Obx(
                                  () => Text(
                                controller.vendor.value?.name ??
                                    '...',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                  FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),

                            Obx(
                                  () => Text(
                                controller.vendor.value
                                    ?.businessName ??
                                    '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                  Colors.white.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  Get.toNamed(
                                    Routes.notifications,
                                  ),
                            ),

                            GestureDetector(
                              onTap: () =>
                                  Get.toNamed(
                                    Routes.profile,
                                  ),
                              child: Obx(() {
                                final vendor =
                                    controller.vendor.value;

                                return CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                  Colors.white
                                      .withValues(
                                    alpha: 0.2,
                                  ),
                                  backgroundImage:
                                  vendor?.profileImageUrl !=
                                      null
                                      ? NetworkImage(
                                    vendor!
                                        .profileImageUrl!,
                                  )
                                      : null,
                                  child:
                                  vendor?.profileImageUrl ==
                                      null
                                      ? Text(
                                    vendor?.name
                                        .isNotEmpty ==
                                        true
                                        ? vendor!
                                        .name[0]
                                        .toUpperCase()
                                        : 'V',
                                    style:
                                    const TextStyle(
                                      color:
                                      Colors
                                          .white,
                                      fontWeight:
                                      FontWeight
                                          .w700,
                                      fontFamily:
                                      'Poppins',
                                    ),
                                  )
                                      : null,
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),

                          Text(
                            controller.todayFormatted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),

                          const Spacer(),

                          Obx(
                                () => Text(
                              '${controller.deliveredToday}/${controller.todayDeliveries.length} Delivered',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight:
                                FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─────────────────────────────
            // Analytics
            // ─────────────────────────────

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ShimmerBox(
                                height: 130,
                                borderRadius: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ShimmerBox(
                                height: 130,
                                borderRadius: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  final rate =
                  (controller.completionRate * 100)
                      .toInt();

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Total Customers',
                              value:
                              '${controller.totalCustomers}',
                              subtitle:
                              '${controller.activeCustomers} active',
                              icon: Icons.people_rounded,
                              gradientColors:
                              AppColors.gradientPurple,
                              onTap: () =>
                                  controller.changeTab(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'Monthly Revenue',
                              value: controller
                                  .monthlyRevenue.value
                                  .inrCompact,
                              subtitle:
                              '${controller.pendingRevenue.value.inrCompact} pending',
                              icon: Icons
                                  .currency_rupee_rounded,
                              gradientColors:
                              AppColors.gradientGreen,
                              onTap: () =>
                                  controller.changeTab(3),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                              children: [
                                const Text(
                                  "Today's Progress",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                    FontWeight.w600,
                                    color: AppColors
                                        .textSecondary,
                                    fontFamily:
                                    'Poppins',
                                  ),
                                ),
                                Text(
                                  '$rate%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                    FontWeight.w800,
                                    color: rate >= 80
                                        ? AppColors
                                        .success
                                        : rate >= 50
                                        ? AppColors
                                        .warning
                                        : AppColors
                                        .error,
                                    fontFamily:
                                    'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            // ─────────────────────────────
            // Quick Actions
            // ─────────────────────────────

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text("Quick Actions", style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _QuickAction(icon: Icons.map_outlined, label: 'Routes', color: Colors.blue, onTap: () => Get.toNamed(Routes.routeList)),
                        _QuickAction(icon: Icons.people_outline, label: 'Staff', color: Colors.orange, onTap: () => Get.toNamed(Routes.staffList)),
                        _QuickAction(icon: Icons.inventory_2_outlined, label: 'Stock', color: Colors.green, onTap: () => Get.toNamed(Routes.inventory)),
                        _QuickAction(icon: Icons.receipt_outlined, label: 'Expense', color: Colors.red, onTap: () => Get.toNamed(Routes.expenses)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─────────────────────────────
            // Deliveries Title
            // ─────────────────────────────

            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  0,
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Deliveries",
                      style:
                      AppTextStyles.headlineSmall,
                    ),
                    GestureDetector(
                      onTap: () =>
                          controller.changeTab(2),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Obx(() {
              final deliveries = controller
                  .todayDeliveries
                  .take(5)
                  .toList();

              if (deliveries.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: EmptyState(
                      title: 'No Deliveries Today',
                      subtitle:
                      'Add subscriptions to auto-generate daily delivery schedules.',
                      icon:
                      Icons.local_shipping_outlined,
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  0,
                ),
                sliver: SliverList(
                  delegate:
                  SliverChildBuilderDelegate(
                        (_, i) => _DeliveryTile(
                      delivery: deliveries[i],
                    ),
                    childCount: deliveries.length,
                  ),
                ),
              );
            }),

            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// Delivery Tile
// ─────────────────────────────────────────────────────────────

class _DeliveryTile extends StatelessWidget {
  final dynamic delivery;

  const _DeliveryTile({
    required this.delivery,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
    Color(delivery.statusColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
              statusColor.withValues(alpha: 0.1),
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              color: statusColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  delivery.customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  delivery.customerAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}
