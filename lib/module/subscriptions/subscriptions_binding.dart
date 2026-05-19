// lib/module/subscriptions/subscriptions_binding.dart
import 'package:get/get.dart';
import '../../data/repositories/subscription_repository.dart';
import 'subscriptions_controller.dart';

class SubscriptionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubscriptionRepository>(() => SubscriptionRepository(), fenix: true);
    Get.lazyPut<SubscriptionsController>(() => SubscriptionsController());
  }
}