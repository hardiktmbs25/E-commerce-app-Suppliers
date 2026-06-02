// lib/modules/customers/add/add_customer_binding.dart
import 'package:get/get.dart';
import '../../../data/repositories/customer_repository.dart';
import 'add_customer_controller.dart';

class AddCustomerBinding extends Bindings {
  @override
  void dependencies() {
    // ConnectivityService is registered permanently in main.dart
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<AddCustomerController>(() => AddCustomerController());
  }
}
