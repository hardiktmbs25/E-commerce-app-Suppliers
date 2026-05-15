// lib/modules/subscriptions/subscriptions_binding.dart
import 'package:get/get.dart';
import '../../data/repositories/customer_repository.dart';
import '../../services/local_storage_service.dart';
import 'subscriptions_controller.dart';

class SubscriptionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<SubscriptionsController>(() => SubscriptionsController());
  }
}