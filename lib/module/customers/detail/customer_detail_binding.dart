// lib/modules/customers/detail/customer_detail_binding.dart
import 'package:get/get.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/billing_repository.dart';
import '../../../data/repositories/delivery_repository.dart';
import 'customer_detail_controller.dart';

class CustomerDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<BillingRepository>(() => BillingRepository(), fenix: true);
    Get.lazyPut<DeliveryRepository>(() => DeliveryRepository(), fenix: true);
    Get.lazyPut<CustomerDetailController>(() => CustomerDetailController());
  }
}