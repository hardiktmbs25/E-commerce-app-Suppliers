// lib/module/deliveries/add/add_delivery_binding.dart
import 'package:get/get.dart';
import '../../../data/repositories/delivery_repository.dart';
import 'add_delivery_controller.dart';

class AddDeliveryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeliveryRepository>(() => DeliveryRepository(), fenix: true);
    Get.lazyPut<AddDeliveryController>(() => AddDeliveryController());
  }
}