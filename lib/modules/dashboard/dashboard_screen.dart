// lib/modules/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
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

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Home',
                  index: 0,
                  current: currentIndex,
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Customers',
                  index: 1,
                  current: currentIndex,
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.local_shipping_rounded,
                  label: 'Delivery',
                  index: 2,
                  current: currentIndex,
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Billing',
                  index: 3,
                  current: currentIndex,
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 4,
                  current: currentIndex,
                  onTap: onTap,
                ),
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
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? AppColors.primary
                  : AppColors.textHint,
            ),

            const SizedBox(height: 4),

            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textHint,
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
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Offline Banner ──
            SliverToBoxAdapter(
              child: Obx(() => !connectivity.isOnline.value
                  ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: AppColors.warning,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 8),
                    Text('Offline Mode — Changes will sync later',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                  ],
                ),
              ) : const SizedBox()),
            ),

            // ── Modern Glass Header ──
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(controller.greeting,
                                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), fontFamily: 'Poppins')),
                            const SizedBox(height: 4),
                            Obx(() => Text(controller.vendor.value?.name ?? '...',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins'))),
                          ],
                        ),
                        _HeaderActions(controller: controller),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _TodaySummaryBar(controller: controller),
                  ],
                ),
              ),
            ),

            // ── Main Content ──
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Performance Grid ──
                  Obx(() {
                    if (controller.isLoading.value) return const ShimmerBox(height: 150, borderRadius: 24);
                    return Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Active Subs',
                            value: '${controller.activeCustomers}',
                            subtitle: 'Total: ${controller.totalCustomers}',
                            icon: Icons.subscriptions_rounded,
                            gradientColors: AppColors.gradientPurple,
                            onTap: () => controller.changeTab(1),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Monthly Rev',
                            value: controller.monthlyRevenue.value.inrCompact,
                            subtitle: '${controller.pendingRevenue.value.inrCompact} pending',
                            icon: Icons.currency_rupee_rounded,
                            gradientColors: AppColors.gradientTeal,
                            onTap: () => controller.changeTab(3),
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 24),
                  
                  // ── Progress Card ──
                  const _SectionHeader(title: "Today's Progress"),
                  const SizedBox(height: 12),
                  _ProgressCard(controller: controller),

                  const SizedBox(height: 32),

                  // ── Quick Actions ──
                  const _SectionHeader(title: "Quick Actions"),
                  const SizedBox(height: 12),
                  _QuickActionsGrid(),

                  const SizedBox(height: 32),

                  // ── Recent Deliveries ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionHeader(title: "Recent Deliveries"),
                      TextButton(
                        onPressed: () => controller.changeTab(2),
                        child: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ]),
              ),
            ),

            // ── Delivery List ──
            Obx(() {
              final deliveries = controller.todayDeliveries.take(5).toList();
              if (deliveries.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: EmptyState(
                      title: 'No Deliveries',
                      subtitle: 'Schedules will appear once slots start.',
                      icon: Icons.local_shipping_outlined,
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => _DeliveryTile(delivery: deliveries[i]),
                    childCount: deliveries.length,
                  ),
                ),
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  final DashboardController controller;
  const _HeaderActions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.notifications_none_rounded, onTap: () => Get.toNamed(Routes.notifications)),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => controller.changeTab(4),
          child: Obx(() {
            final vendor = controller.vendor.value;
            return Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                backgroundImage: vendor?.profileImageUrl != null ? NetworkImage(vendor!.profileImageUrl!) : null,
                child: vendor?.profileImageUrl == null ? Text(vendor?.name[0].toUpperCase() ?? 'V', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _TodaySummaryBar extends StatelessWidget {
  final DashboardController controller;
  const _TodaySummaryBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, color: Colors.white.withOpacity(0.8), size: 16),
          const SizedBox(width: 10),
          Text(controller.todayFormatted, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
          const Spacer(),
          Obx(() => Text('${controller.deliveredToday}/${controller.todayDeliveries.length} Done',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Poppins'))),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final DashboardController controller;
  const _ProgressCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rate = (controller.completionRate * 100).toInt();
      final color = rate >= 80 ? AppColors.success : rate >= 50 ? AppColors.warning : AppColors.error;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70, height: 70,
                  child: CircularProgressIndicator(
                    value: controller.completionRate,
                    strokeWidth: 8,
                    backgroundColor: color.withOpacity(0.1),
                    color: color,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text('$rate%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color, fontFamily: 'Poppins')),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rate >= 100 ? "All Clear!" : "Almost There", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text("${controller.pendingToday} deliveries remaining for today's active slots.",
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      children: [
        _QuickActionItem(icon: Icons.map_rounded, label: 'Routes', color: const Color(0xFF3B82F6), onTap: () => Get.toNamed(Routes.routeList)),
        _QuickActionItem(icon: Icons.badge_rounded, label: 'Staff', color: const Color(0xFFF59E0B), onTap: () => Get.toNamed(Routes.staffList)),
        _QuickActionItem(icon: Icons.inventory_2_rounded, label: 'Stock', color: const Color(0xFF10B981), onTap: () => Get.toNamed(Routes.inventory)),
        _QuickActionItem(icon: Icons.receipt_rounded, label: 'Expenses', color: const Color(0xFFEF4444), onTap: () => Get.toNamed(Routes.expenses)),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Poppins'));
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


