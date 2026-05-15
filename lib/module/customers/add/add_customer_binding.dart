// lib/modules/customers/add/add_customer_binding.dart
import 'package:get/get.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../services/connectivity_service.dart';
import 'add_customer_controller.dart';

class AddCustomerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<ConnectivityService>(() => ConnectivityService(), fenix: true);
    Get.lazyPut<AddCustomerController>(() => AddCustomerController());
  }
}