// lib/modules/analytics/analytics_binding.dart
import 'package:get/get.dart';
import '../../data/repositories/billing_repository.dart';
import 'analytics_controller.dart';

class AnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillingRepository>(() => BillingRepository(), fenix: true);
    Get.lazyPut<AnalyticsController>(() => AnalyticsController());
  }
}