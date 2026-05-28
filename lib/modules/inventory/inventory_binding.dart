import 'package:get/get.dart';
import '../../data/repositories/inventory_repository.dart';
import 'inventory_controller.dart';

class InventoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventoryRepository>(() => InventoryRepository());
    Get.lazyPut<InventoryController>(() => InventoryController());
  }
}