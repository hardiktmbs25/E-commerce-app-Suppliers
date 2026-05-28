// lib/core/bindings/initial_binding.dart

import 'package:get/get.dart';

// Repositories
import '../../data/repositories/vendor_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/billing_repository.dart';

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
    // CORE SERVICES
    // =========================================================
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<SyncService>(SyncService(), permanent: true);
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
    Get.put<NotificationService>(NotificationService(), permanent: true);

    // =========================================================
    // ASYNC INITIALIZED SERVICES
    // =========================================================
    Get.put<LocalizationService>(LocalizationService(), permanent: true);
    Get.put<PermissionService>(PermissionService(), permanent: true);
    Get.put<VoiceService>(VoiceService(), permanent: true);

    // =========================================================
    // REPOSITORIES
    // =========================================================
    Get.put<VendorRepository>(VendorRepository(), permanent: true);
    Get.put<CustomerRepository>(CustomerRepository(), permanent: true);
    Get.put<BillingRepository>(BillingRepository(), permanent: true);

    // =========================================================
    // BUSINESS SERVICES
    // =========================================================
    Get.put<LedgerService>(LedgerService(), permanent: true);
    Get.put<CustomerBalanceService>(CustomerBalanceService(), permanent: true);
    Get.put<DeliveryGenerationService>(DeliveryGenerationService(), permanent: true,);
    Get.put<BillingGenerationService>(BillingGenerationService(), permanent: true,);
    Get.put<PaymentService>(PaymentService(), permanent: true);
    Get.put<DeliverySchedulerService>(DeliverySchedulerService(), permanent: true,);
    Get.put<BillingService>(BillingService(), permanent: true);
    Get.put<WalletService>(WalletService(), permanent: true);

    // =========================================================
    // UTILITY SERVICES
    // =========================================================
    Get.put<PdfService>(PdfService(), permanent: true);
    Get.put<WhatsappService>(WhatsappService(), permanent: true);
    Get.put<ExportService>(ExportService(), permanent: true);
  }
}
