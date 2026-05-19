// lib/module/subscriptions/add/add_subscription_binding.dart
import 'package:get/get.dart';
import '../../../data/repositories/customer_repository.dart';
import 'add_subscription_controller.dart';

class AddSubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<AddSubscriptionController>(() => AddSubscriptionController());
  }
}