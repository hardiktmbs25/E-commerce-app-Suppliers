import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'routes_controller.dart';

class RoutesScreen extends GetView<RoutesController> {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('routes'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, size: 32, color: AppColors.primary),
            onPressed: () => _showAddRouteDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.routes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_outlined, size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No routes created yet', style: Get.textTheme.titleMedium),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _showAddRouteDialog(context),
                  child: const Text('Create First Route'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          itemCount: controller.routes.length,
          itemBuilder: (context, index) {
            final route = controller.routes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${route.customerIds.length} Customers',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (route.areaName != null) ...[
                      const SizedBox(height: 4),
                      Text(route.areaName!, style: TextStyle(color: Colors.grey[600])),
                    ],
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            route.deliveryBoyName ?? 'Not Assigned',
                            style: TextStyle(
                              color: route.deliveryBoyId == null ? Colors.red : Colors.black,
                              fontWeight: route.deliveryBoyId == null ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showAssignStaffDialog(context, route.id),
                          child: const Text('Assign Staff'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddRouteDialog(BuildContext context) {
    final nameController = TextEditingController();
    final areaController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Create New Route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Route Name (e.g. Morning Sector 1)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: areaController,
              decoration: const InputDecoration(labelText: 'Area (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                controller.addRoute(nameController.text, areaController.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAssignStaffDialog(BuildContext context, String routeId) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Assign Delivery Boy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Obx(() => controller.deliveryBoys.isEmpty
                ? const Text('No delivery boys available. Please add staff first.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.deliveryBoys.length,
                    itemBuilder: (context, index) {
                      final staff = controller.deliveryBoys[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(staff.name),
                        subtitle: Text(staff.phone),
                        onTap: () {
                          controller.assignDeliveryBoy(routeId, staff);
                          Get.back();
                        },
                      );
                    },
                  )),
          ],
        ),
      ),
    );
  }
}