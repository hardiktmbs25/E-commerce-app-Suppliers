// lib/modules/deliveries/extra_order/extra_order_binding.dart
import 'package:get/get.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/delivery_repository.dart';
import 'extra_order_controller.dart';

class ExtraOrderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeliveryRepository>(() => DeliveryRepository(), fenix: true);
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<ExtraOrderController>(() => ExtraOrderController());
  }
}
