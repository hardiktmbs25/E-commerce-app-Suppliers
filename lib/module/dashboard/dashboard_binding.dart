// lib/modules/dashboard/dashboard_binding.dart
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../data/repositories/vendor_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/billing_repository.dart';
import '../../services/connectivity_service.dart';
import '../../services/notification_service.dart';
import 'dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Services (fenix — safe re-register)
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<ConnectivityService>(() => ConnectivityService(), fenix: true);
    Get.lazyPut<NotificationService>(() => NotificationService(), fenix: true);
    // Repositories
    Get.lazyPut<VendorRepository>(() => VendorRepository(), fenix: true);
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<DeliveryRepository>(() => DeliveryRepository(), fenix: true);
    Get.lazyPut<BillingRepository>(() => BillingRepository(), fenix: true);
    // Controller
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}