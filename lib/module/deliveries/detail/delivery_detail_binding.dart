// lib/module/deliveries/detail/delivery_detail_binding.dart
import 'package:get/get.dart';
import '../../../data/repositories/delivery_repository.dart';
import 'delivery_detail_controller.dart';

class DeliveryDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeliveryRepository>(() => DeliveryRepository(), fenix: true);
    Get.lazyPut<DeliveryDetailController>(() => DeliveryDetailController());
  }
}