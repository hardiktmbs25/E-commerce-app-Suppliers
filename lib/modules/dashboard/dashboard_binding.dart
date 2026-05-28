// lib/modules/dashboard/dashboard_binding.dart
//
// FIX: Removed the duplicate `Get.put<DeliverySchedulerService>()` call.
//
// PROBLEM: DeliverySchedulerService was registered here AND now also in
// InitialBinding (permanent). Calling Get.put() on an already-registered
// permanent service would silently replace it, resetting the midnight timer
// and any in-progress scheduling state — causing missed daily generation.
//
// SOLUTION: Trust InitialBinding to have already registered the service
// before this binding runs. DashboardBinding should only set up the
// dashboard-scoped repositories and controllers.

import 'package:get/get.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/delivery_repository.dart';
import '../billing/billing_controller.dart';
import '../customers/customers_controller.dart';
import '../deliveries/deliveries_controller.dart';
import '../profile/profile_controller.dart';
import 'dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {

    // ── Repositories ──────────────────────────────────────────────────────
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<DeliveryRepository>(() => DeliveryRepository(), fenix: true);

    // ── Controllers ────────────────────────────────────────────────────────
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<CustomersController>(() => CustomersController(), fenix: true);
    Get.lazyPut<DeliveriesController>(() => DeliveriesController(), fenix: true);
    Get.lazyPut<BillingController>(() => BillingController(), fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
  }
}
