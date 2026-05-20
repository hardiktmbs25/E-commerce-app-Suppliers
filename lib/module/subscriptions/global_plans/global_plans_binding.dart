// lib/module/subscriptions/global_plans/global_plans_binding.dart
import 'package:get/get.dart';
import '../../../data/repositories/global_plan_repository.dart';
import 'global_plans_controller.dart';

class GlobalPlansBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GlobalPlanRepository>(() => GlobalPlanRepository(), fenix: true);
    Get.lazyPut<GlobalPlansController>(() => GlobalPlansController());
  }
}