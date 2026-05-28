import 'package:get/get.dart';
import '../../data/models/inventory_model.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../services/auth_service.dart';

class InventoryController extends GetxController {
  final InventoryRepository _inventoryRepo = Get.find();

  final RxList<InventoryModel> items = <InventoryModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    items.bindStream(_inventoryRepo.watchInventory());
  }

  Future<void> addProduct(String name, double initialStock, double lowStock) async {
    try {
      final newItem = InventoryModel(
        id: '',
        vendorId: AuthService.to.vendorId,
        productName: name,
        currentStock: initialStock,
        lowStockAlert: lowStock,
        updatedAt: DateTime.now(),
      );
      await _inventoryRepo.updateStock(newItem);
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add product: $e');
    }
  }

  Future<void> updateStock(InventoryModel item, double change, bool isAddition) async {
    final newStock = isAddition ? item.currentStock + change : item.currentStock - change;
    final updated = item.copyWith(currentStock: newStock);
    await _inventoryRepo.updateStock(updated);
    await _inventoryRepo.addStockMovement(item.id, change, isAddition ? 'in' : 'out');
  }
}