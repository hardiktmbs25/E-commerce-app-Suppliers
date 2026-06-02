// lib/modules/deliveries/history/delivery_history_binding.dart
import 'package:get/get.dart';
import '../../../data/repositories/delivery_repository.dart';
import 'delivery_history_controller.dart';

class DeliveryHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeliveryRepository>(() => DeliveryRepository(), fenix: true);
    Get.lazyPut<DeliveryHistoryController>(() => DeliveryHistoryController());
  }
}
