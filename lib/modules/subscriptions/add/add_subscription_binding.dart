// lib/modules/subscriptions/add/add_subscription_binding.dart

import 'package:get/get.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../services/delivery_scheduler_service.dart';
import 'add_subscription_controller.dart';

class AddSubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    // DeliverySchedulerService must exist (registered permanently at app start)
    if (!Get.isRegistered<DeliverySchedulerService>()) {
      Get.put<DeliverySchedulerService>(
        DeliverySchedulerService(),
        permanent: true,
      );
    }

    // SubscriptionRepository
    if (!Get.isRegistered<SubscriptionRepository>()) {
      Get.put<SubscriptionRepository>(SubscriptionRepository(), permanent: true);
    }

    Get.lazyPut<AddSubscriptionController>(
          () => AddSubscriptionController(),
    );
  }
}
