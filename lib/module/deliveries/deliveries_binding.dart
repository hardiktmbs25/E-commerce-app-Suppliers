// lib/module/deliveries/deliveries_binding.dart
import 'package:get/get.dart';
import '../../data/repositories/delivery_repository.dart';
import 'deliveries_controller.dart';

class DeliveriesBinding extends Bindings {
  @override
  void dependencies() {
    // ConnectivityService is registered permanently in main.dart
    Get.lazyPut<DeliveryRepository>(() => DeliveryRepository(), fenix: true);
    Get.lazyPut<DeliveriesController>(() => DeliveriesController());
  }
}