// lib/modules/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_box.dart';
import '../../routes/app_routes.dart';
import '../../services/connectivity_service.dart';
import 'dashboard_controller.dart';
import '../customers/customers_screen.dart';
import '../deliveries/deliveries_screen.dart';
import '../billing/billing_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.currentTabIndex.value,
        children: const [
          _HomeTab(),
          CustomersScreen(),
          DeliveriesScreen(),
          BillingScreen(),
          ProfileScreen(),
        ],
      )),
      bottomNavigationBar: Obx(() => _BottomNav(
        currentIndex: controller.currentTabIndex.value,
        onTap: controller.changeTab,
      )),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded,
                  label: 'Home',      index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded,
                  label: 'Customers', index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping_rounded,
                  label: 'Deliveries', index: 2, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded,
                  label: 'Billing',   index: 3, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,
                  label: 'Profile',   index: 4, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.activeIcon,
    required this.label, required this.index,
    required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon,
                color: isActive ? AppColors.primary : AppColors.textHint, size: 22),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textHint,
              fontFamily: 'Poppins',
            )),
          ],
        ),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────
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
            // ── App Bar ──────────────────────────────────────────────────
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
                    Text('Offline — changes will sync when connected',
                        style: TextStyle(color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                  ],
                ),
              )
                  : const SizedBox()),
            ),

            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.gradientPurple,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(controller.greeting,
                                style: TextStyle(fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                    fontFamily: 'Poppins')),
                            const SizedBox(height: 2),
                            Text(
                              controller.vendor.value?.name ?? '...',
                              style: const TextStyle(fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white, fontFamily: 'Poppins'),
                            ),
                            Text(
                              controller.vendor.value?.businessName ?? '',
                              style: TextStyle(fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                  fontFamily: 'Poppins'),
                            ),
                          ],
                        )),
                        Row(children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.white),
                            onPressed: () => Get.toNamed(Routes.notifications),
                          ),
                          GestureDetector(
                            onTap: () => Get.toNamed(Routes.profile),
                            child: Obx(() => CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              backgroundImage: controller.vendor.value?.profileImageUrl != null
                                  ? NetworkImage(controller.vendor.value!.profileImageUrl!)
                                  : null,
                              child: controller.vendor.value?.profileImageUrl == null
                                  ? Text(
                                controller.vendor.value?.name.isNotEmpty == true
                                    ? controller.vendor.value!.name[0].toUpperCase()
                                    : 'V',
                                style: const TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                              )
                                  : null,
                            )),
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Today's date + quick summary
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Obx(() => Text(controller.todayFormatted,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 12, fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins'))),
                          const Spacer(),
                          Obx(() => Text(
                            '${controller.deliveredToday}/${controller.todayDeliveries.length} Delivered',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 12, fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins'),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Analytics Cards ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Column(children: [
                      Row(children: [
                        Expanded(child: ShimmerBox(height: 130, borderRadius: 20)),
                        SizedBox(width: 12),
                        Expanded(child: ShimmerBox(height: 130, borderRadius: 20)),
                      ]),
                      SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: ShimmerBox(height: 130, borderRadius: 20)),
                        SizedBox(width: 12),
                        Expanded(child: ShimmerBox(height: 130, borderRadius: 20)),
                      ]),
                      SizedBox(height: 12),
                      ShimmerBox(height: 130, borderRadius: 20),
                    ]);
                  }
                  return Column(
                    children: [
                      Row(children: [
                        Expanded(child: StatCard(
                          title: 'Total Customers',
                          value: '${controller.totalCustomers}',
                          subtitle: '${controller.activeCustomers} active',
                          icon: Icons.people_rounded,
                          gradientColors: AppColors.gradientPurple,
                          onTap: () => controller.changeTab(1),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: StatCard(
                          title: 'Monthly Revenue',
                          value: controller.monthlyRevenue.value.inrCompact,
                          subtitle: '${controller.pendingRevenue.value.inrCompact} pending',
                          icon: Icons.currency_rupee_rounded,
                          gradientColors: AppColors.gradientGreen,
                          onTap: () => controller.changeTab(3),
                        )),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: StatCard(
                          title: 'Today\'s Deliveries',
                          value: '${controller.todayDeliveries.length}',
                          subtitle: '${controller.pendingToday} pending',
                          icon: Icons.local_shipping_rounded,
                          gradientColors: AppColors.gradientBlue,
                          onTap: () => controller.changeTab(2),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: StatCard(
                          title: 'Pending Bills',
                          value: '${controller.totalPendingBills}',
                          subtitle: 'Awaiting payment',
                          icon: Icons.receipt_long_rounded,
                          gradientColors: AppColors.gradientOrange,
                          onTap: () => controller.changeTab(3),
                        )),
                      ]),
                      const SizedBox(height: 12),
                      // Completion rate card
                      Obx(() {
                        final rate = (controller.completionRate * 100).toInt();
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Today's Progress",
                                      style: TextStyle(fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                          fontFamily: 'Poppins')),
                                  Text('$rate%',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: rate >= 80
                                              ? AppColors.success
                                              : rate >= 50
                                              ? AppColors.warning
                                              : AppColors.error,
                                          fontFamily: 'Poppins')),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: controller.completionRate.clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: AppColors.border,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    rate >= 80 ? AppColors.success : rate >= 50
                                        ? AppColors.warning : AppColors.error,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(children: [
                                _ProgressChip('✅ Delivered', controller.deliveredToday, AppColors.success),
                                const SizedBox(width: 8),
                                _ProgressChip('⏳ Pending', controller.pendingToday, AppColors.warning),
                                const SizedBox(width: 8),
                                _ProgressChip('❌ Missed', controller.missedToday, AppColors.error),
                              ]),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ),
            ),

            // ── Quick Actions ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Actions',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary, fontFamily: 'Poppins')),
                    const SizedBox(height: 14),
                    Row(children: [
                      _QuickAction(icon: Icons.person_add_outlined,
                          label: 'Add\nCustomer', color: AppColors.primary,
                          onTap: () => Get.toNamed(Routes.addCustomer)),
                      _QuickAction(icon: Icons.check_circle_outline_rounded,
                          label: 'Mark\nDeliveries', color: AppColors.success,
                          onTap: () => controller.changeTab(2)),
                      _QuickAction(icon: Icons.receipt_outlined,
                          label: 'Generate\nBill', color: AppColors.warning,
                          onTap: () => controller.changeTab(3)),
                      _QuickAction(icon: Icons.analytics_outlined,
                          label: 'Analytics', color: AppColors.info,
                          onTap: () => Get.toNamed(Routes.analytics)),
                    ]),
                  ],
                ),
              ),
            ),

            // ── Today's Deliveries Preview ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Text("Today's Deliveries",
                        style: AppTextStyles.headlineSmall)),
                    GestureDetector(
                      onTap: () => controller.changeTab(2),
                      child: const Text('View All',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.primary, fontFamily: 'Poppins')),
                    ),
                  ],
                ),
              ),
            ),
            Obx(() {
              final deliveries = controller.todayDeliveries.take(5).toList();
              if (deliveries.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: EmptyState(
                      title: 'No Deliveries Today',
                      subtitle: 'Add subscriptions to auto-generate daily delivery schedules.',
                      icon: Icons.local_shipping_outlined,
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => _DeliveryTile(delivery: deliveries[i]),
                    childCount: deliveries.length,
                  ),
                ),
              );
            }),

            // ── Pending Payments Preview ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pending Payments',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary, fontFamily: 'Poppins')),
                    GestureDetector(
                      onTap: () => controller.changeTab(3),
                      child: const Text('View All',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.primary, fontFamily: 'Poppins')),
                    ),
                  ],
                ),
              ),
            ),
            Obx(() {
              final invoices = controller.pendingInvoices.take(3).toList();
              if (invoices.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text('🎉 All payments are up to date!',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary,
                            fontFamily: 'Poppins')),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => _PendingPaymentTile(invoice: invoices[i]),
                    childCount: invoices.length,
                  ),
                ),
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ── Progress chip ─────────────────────────────────────────────────────────────
class _ProgressChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _ProgressChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label ($count)',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: color, fontFamily: 'Poppins')),
    );
  }
}

// ── Quick action button ────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: color, fontFamily: 'Poppins', height: 1.3),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

// ── Delivery tile ─────────────────────────────────────────────────────────────
class _DeliveryTile extends StatelessWidget {
  final dynamic delivery;
  const _DeliveryTile({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(delivery.statusColor);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.local_shipping_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(delivery.customerName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary, fontFamily: 'Poppins')),
                Text(delivery.customerAddress,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary,
                        fontFamily: 'Poppins'),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${delivery.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary, fontFamily: 'Poppins')),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(delivery.status.name.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                        color: statusColor, fontFamily: 'Poppins')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pending payment tile ──────────────────────────────────────────────────────
class _PendingPaymentTile extends StatelessWidget {
  final dynamic invoice;
  const _PendingPaymentTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: invoice.isOverdue ? AppColors.error.withOpacity(0.3) : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: (invoice.isOverdue ? AppColors.error : AppColors.warning).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.receipt_long_rounded,
              color: invoice.isOverdue ? AppColors.error : AppColors.warning, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invoice.customerName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary, fontFamily: 'Poppins')),
            Text('${invoice.monthName} ${invoice.year}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary,
                    fontFamily: 'Poppins')),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${invoice.pendingAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                  color: AppColors.error, fontFamily: 'Poppins')),
          if (invoice.isOverdue)
            const Text('OVERDUE', style: TextStyle(fontSize: 9,
                fontWeight: FontWeight.w800, color: AppColors.error, fontFamily: 'Poppins')),
        ]),
      ]),
    );
  }
}