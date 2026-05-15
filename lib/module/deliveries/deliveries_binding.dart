// lib/modules/deliveries/deliveries_binding.dart
import 'package:get/get.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../services/connectivity_service.dart';
import 'deliveries_controller.dart';

class DeliveriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeliveryRepository>(() => DeliveryRepository(), fenix: true);
    Get.lazyPut<ConnectivityService>(() => ConnectivityService(), fenix: true);
    Get.lazyPut<DeliveriesController>(() => DeliveriesController());
  }
}