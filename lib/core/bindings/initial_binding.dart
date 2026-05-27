// lib/core/bindings/initial_binding.dart
//
// FIX: DeliverySchedulerService "not found" crash.
//
// PROBLEM: DeliverySchedulerService was registered inside DashboardBinding,
// which only runs when the user navigates to the dashboard. Any code path
// that calls Get.find<DeliverySchedulerService>() before that (e.g. from a
// deep-link or a background task) would throw:
//   "DeliverySchedulerService not found"
//
// SOLUTION: Register ALL long-lived services here as permanent singletons
// via initialBinding in GetMaterialApp (see main.dart). This guarantees
// every service is available from the very first frame, regardless of route.

import 'package:get/get.dart';
import '../../data/repositories/billing_repository.dart';
import '../../services/billing_service.dart';
import '../../services/delivery_scheduler_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../data/repositories/vendor_repository.dart';
// New Services imports
import '../../services/ledger_service.dart';
import '../../services/customer_balance_service.dart';
import '../../services/delivery_generation_service.dart';
import '../../services/billing_generation_service.dart';
import '../../services/payment_service.dart';
import '../../services/sync_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {

    // Core services
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<SyncService>(SyncService(), permanent: true);
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
    Get.put<NotificationService>(NotificationService(), permanent: true);

    // Repositories FIRST
    Get.put<VendorRepository>(VendorRepository(), permanent: true);
    Get.put<BillingRepository>(BillingRepository(), permanent: true);

    // Services that depend on repositories
    Get.put<LedgerService>(LedgerService(), permanent: true);
    Get.put<CustomerBalanceService>(CustomerBalanceService(), permanent: true,);

    Get.put<DeliveryGenerationService>(DeliveryGenerationService(), permanent: true,);

    Get.put<BillingGenerationService>(BillingGenerationService(), permanent: true,);

    Get.put<PaymentService>(PaymentService(), permanent: true,);

    Get.put<DeliverySchedulerService>(DeliverySchedulerService(), permanent: true,);

    Get.put<BillingService>(BillingService(), permanent: true,);
  }
}