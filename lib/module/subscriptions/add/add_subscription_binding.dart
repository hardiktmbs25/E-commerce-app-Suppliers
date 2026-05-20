// lib/module/subscriptions/add/add_subscription_binding.dart
import 'package:get/get.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../services/delivery_scheduler_service.dart';
import 'add_subscription_controller.dart';

class AddSubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure scheduler is available (registered permanently on first use)
    if (!Get.isRegistered<DeliverySchedulerService>()) {
      Get.put<DeliverySchedulerService>(DeliverySchedulerService(), permanent: true);
    }
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<AddSubscriptionController>(() => AddSubscriptionController());
  }
}