// lib/core/bindings/initial_binding.dart

import 'package:get/get.dart';

// Repositories
import '../../data/repositories/vendor_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/billing_repository.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/repositories/global_plan_repository.dart';

// Core Services
import '../../services/auth_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/notification_service.dart';
import '../../services/sync_service.dart';

// Business Services
import '../../services/ledger_service.dart';
import '../../services/customer_balance_service.dart';
import '../../services/delivery_generation_service.dart';
import '../../services/billing_generation_service.dart';
import '../../services/payment_service.dart';
import '../../services/delivery_scheduler_service.dart';
import '../../services/billing_service.dart';
import '../../services/wallet_service.dart';

// Utility Services
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';
import '../../services/export_service.dart';
import '../../services/voice_service.dart';
import '../../services/localization_service.dart';
import '../../services/permission_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {

    // =========================================================
    // CORE SERVICES (Global singletons)
    // =========================================================
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<SyncService>(SyncService(), permanent: true);
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
    Get.put<NotificationService>(NotificationService(), permanent: true);
    Get.put<LocalizationService>(LocalizationService(), permanent: true);

    // =========================================================
    // REPOSITORIES (Lazy loaded but global)
    // =========================================================
    Get.lazyPut<VendorRepository>(() => VendorRepository(), fenix: true);
    Get.lazyPut<CustomerRepository>(() => CustomerRepository(), fenix: true);
    Get.lazyPut<BillingRepository>(() => BillingRepository(), fenix: true);
    Get.lazyPut<DeliveryRepository>(() => DeliveryRepository(), fenix: true);
    Get.lazyPut<SubscriptionRepository>(() => SubscriptionRepository(), fenix: true);
    Get.lazyPut<GlobalPlanRepository>(() => GlobalPlanRepository(), fenix: true);

    // =========================================================
    // BUSINESS ENGINES (Permanent background workers)
    // =========================================================
    Get.put<DeliverySchedulerService>(DeliverySchedulerService(), permanent: true);
    Get.put<DeliveryGenerationService>(DeliveryGenerationService(), permanent: true);
    
    // =========================================================
    // BUSINESS SERVICES (Lazy with fenix)
    // =========================================================
    Get.lazyPut<LedgerService>(() => LedgerService(), fenix: true);
    Get.lazyPut<CustomerBalanceService>(() => CustomerBalanceService(), fenix: true);
    Get.lazyPut<BillingGenerationService>(() => BillingGenerationService(), fenix: true);
    Get.lazyPut<PaymentService>(() => PaymentService(), fenix: true);
    Get.lazyPut<BillingService>(() => BillingService(), fenix: true);
    Get.lazyPut<WalletService>(() => WalletService(), fenix: true);

    // =========================================================
    // UTILITY SERVICES (Lazy)
    // =========================================================
    Get.lazyPut<PermissionService>(() => PermissionService(), fenix: true);
    Get.lazyPut<VoiceService>(() => VoiceService(), fenix: true);
    Get.lazyPut<PdfService>(() => PdfService(), fenix: true);
    Get.lazyPut<WhatsappService>(() => WhatsappService(), fenix: true);
    Get.lazyPut<ExportService>(() => ExportService(), fenix: true);
  }
}
