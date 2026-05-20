// lib/module/deliveries/deliveries_binding.dart
import 'package:get/get.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../services/delivery_scheduler_service.dart';
import 'deliveries_controller.dart';

class DeliveriesBinding extends Bindings {
  @override
  void dependencies() {
    // DeliverySchedulerService is a permanent singleton — put once, reused everywhere
    if (!Get.isRegistered<DeliverySchedulerService>()) {
      Get.put<DeliverySchedulerService>(DeliverySchedulerService(), permanent: true);
    }
    Get.lazyPut<DeliveryRepository>(() => DeliveryRepository(), fenix: true);
    Get.lazyPut<DeliveriesController>(() => DeliveriesController());
  }
}