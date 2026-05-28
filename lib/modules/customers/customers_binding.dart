// lib/modules/customers/customers_binding.dart
import 'package:get/get.dart';
import '../../data/repositories/customer_repository.dart';
import 'customers_controller.dart';

class CustomersBinding extends Bindings {
  @override
  void dependencies() {
    // ConnectivityService is registered permanently in main.dart
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.put(CustomersController());
  }
}
