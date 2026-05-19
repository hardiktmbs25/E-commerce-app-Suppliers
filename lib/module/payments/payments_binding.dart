// lib/module/payments/payments_binding.dart
import 'package:get/get.dart';
import '../../data/repositories/billing_repository.dart';
import 'payments_controller.dart';

class PaymentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillingRepository>(() => BillingRepository(), fenix: true);
    Get.lazyPut<PaymentsController>(() => PaymentsController());
  }
}