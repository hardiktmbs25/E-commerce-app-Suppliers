import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/inventory_model.dart';
import 'inventory_controller.dart';

class InventoryScreen extends GetView<InventoryController> {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('inventory'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, size: 32, color: AppColors.primary),
            onPressed: () => _showAddProductDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No items in inventory', style: Get.textTheme.titleMedium),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _showAddProductDialog(context),
                  child: const Text('Add First Item'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          itemCount: controller.items.length,
          itemBuilder: (context, index) {
            final item = controller.items[index];
            final isLow = item.currentStock <= item.lowStockAlert;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isLow ? Colors.red.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.inventory,
                            color: isLow ? Colors.red : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              if (isLow)
                                const Text('LOW STOCK ALERT', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Text(
                          '${item.currentStock} ${item.unit}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isLow ? Colors.red : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StockActionBtn(
                          icon: Icons.remove,
                          label: 'OUT',
                          color: Colors.orange,
                          onTap: () => _showStockUpdateDialog(context, item, false),
                        ),
                        _StockActionBtn(
                          icon: Icons.add,
                          label: 'IN',
                          color: Colors.green,
                          onTap: () => _showStockUpdateDialog(context, item, true),
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

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final alertController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add New Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
            const SizedBox(height: 12),
            TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Initial Stock'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: alertController, decoration: const InputDecoration(labelText: 'Low Stock Alert Level'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                controller.addProduct(
                  nameController.text,
                  double.tryParse(stockController.text) ?? 0,
                  double.tryParse(alertController.text) ?? 10,
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showStockUpdateDialog(BuildContext context, InventoryModel item, bool isAddition) {
    final amountController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text(isAddition ? 'Stock IN' : 'Stock OUT'),
        content: TextField(
          controller: amountController,
          decoration: InputDecoration(labelText: 'Amount of ${item.unit}'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(amountController.text);
              if (val != null) {
                controller.updateStock(item, val, isAddition);
                Get.back();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _StockActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StockActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}