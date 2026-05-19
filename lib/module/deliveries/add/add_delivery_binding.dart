// lib/module/deliveries/add/add_delivery_binding.dart

import 'package:get/get.dart';
import 'add_delivery_controller.dart';

class AddDeliveryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddDeliveryController>(
          () => AddDeliveryController(),
    );
  }
}