// lib/module/billing/billing_binding.dart
import 'package:get/get.dart';
import '../../data/repositories/billing_repository.dart';
import '../../data/repositories/customer_repository.dart';
import 'billing_controller.dart';

class BillingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillingRepository>(() => BillingRepository(), fenix: true);
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<BillingController>(() => BillingController());
  }
}