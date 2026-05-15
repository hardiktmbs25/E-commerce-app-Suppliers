// lib/modules/customers/customers_binding.dart
import 'package:get/get.dart';
import '../../data/repositories/customer_repository.dart';
import '../../services/connectivity_service.dart';
import 'customers_controller.dart';

class CustomersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<ConnectivityService>(() => ConnectivityService(), fenix: true);
    // Get.lazyPut<CustomersController>(() => CustomersController());
    Get.put(CustomersController());
  }
}