// lib/modules/customers/customers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_box.dart';
import '../../widgets/dialogs/confirm_dialog.dart';
import 'customers_controller.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CustomersController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => Get.toNamed(Routes.addCustomer),
          ),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            onChanged: ctrl.setSearch,
            decoration: InputDecoration(
              hintText: 'Search by name, phone, address...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textHint),
              suffixIcon: Obx(() => ctrl.searchQuery.value.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () { ctrl.setSearch(''); },
              )
                  : const SizedBox()),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'active', 'inactive', 'paused'].map((f) {
                final isSelected = ctrl.statusFilter.value == f;
                return GestureDetector(
                  onTap: () => ctrl.setFilter(f),
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
                    child: Text(f,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        )),
                  ),
                );
              }).toList(),
            ),
          )),
        ),
        // List
        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value) return const ShimmerList();
            if (ctrl.filteredCustomers.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: EmptyState(
                    title: 'No Customers Found',
                    subtitle: ctrl.searchQuery.value.isNotEmpty
                        ? 'Try a different search term.'
                        : 'Add your first customer to get started.',
                    icon: Icons.people_outline_rounded,
                    actionLabel: 'Add Customer',
                    onAction: () => Get.toNamed(Routes.addCustomer),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: ctrl.filteredCustomers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final customer = ctrl.filteredCustomers[i];
                return Slidable(
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => Get.toNamed(Routes.customerDetail,
                            arguments: customer),
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12)),
                      ),
                      SlidableAction(
                        onPressed: (_) async {
                          final confirm = await showConfirmDialog(
                            title: 'Delete Customer',
                            message: 'Are you sure you want to delete ${customer.name}? This cannot be undone.',
                            confirmLabel: 'Delete',
                            isDangerous: true,
                          );
                          if (confirm == true) ctrl.deleteCustomer(customer);
                        },
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12)),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () => Get.toNamed(Routes.customerDetail, arguments: customer),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: Row(children: [
                        // Avatar
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700, color: AppColors.primary,
                              fontFamily: 'Poppins', fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(customer.name,
                                  style: const TextStyle(fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Poppins'))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: customer.isActive
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  customer.statusStr,
                                  style: TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w700,
                                    color: customer.isActive ? AppColors.success : AppColors.error,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 3),
                            Text(customer.phone,
                                style: const TextStyle(fontSize: 12,
                                    color: AppColors.textSecondary, fontFamily: 'Poppins')),
                            Text(customer.address,
                                style: const TextStyle(fontSize: 11,
                                    color: AppColors.textHint, fontFamily: 'Poppins'),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        )),
                        if (customer.hasPendingAmount)
                          Column(children: [
                            Text('₹${customer.pendingAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.error, fontFamily: 'Poppins')),
                            const Text('pending', style: TextStyle(fontSize: 9,
                                color: AppColors.error, fontFamily: 'Poppins')),
                          ]),
                      ]),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_customers',
        onPressed: () => Get.toNamed(Routes.addCustomer),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}