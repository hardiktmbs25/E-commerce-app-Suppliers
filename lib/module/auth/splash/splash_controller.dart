// lib/modules/auth/splash/splash_controller.dart
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/local_storage_service.dart';
import '../../../data/repositories/vendor_repository.dart';
import '../../../services/notification_service.dart';
import '../../../core/utils/logger.dart';

class SplashController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final VendorRepository _vendorRepo = Get.find<VendorRepository>();
  @override
  void onReady() {
    super.onReady();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Give splash animation time to show
    await Future.delayed(const Duration(milliseconds: 1800));
    // Check if first launch (show onboarding)
    final isFirstLaunch = LocalStorageService.getSetting<bool>(
        'onboarding_done', defaultValue: false)!;
    if (!isFirstLaunch) {
      Get.offAllNamed(Routes.onboarding);
      return;
    }

    // Check Firebase auth session
    final user = _auth.currentUser;
    if (user == null) {
      Get.offAllNamed(Routes.login);
      return;
    }

    // Fetch vendor profile (local-first, then sync)
    final result = await _vendorRepo.fetchVendor(user.uid);
    result.fold(
          (failure) {
            AppLogger.e('Splash: vendor fetch failed', failure.message);
        Get.offAllNamed(Routes.login);
      },
          (vendor) async {
            // Update FCM token
        final token = await Get.find<NotificationService>().getToken();
        if (token != null) {
          await _vendorRepo.updateFcmToken(user.uid, token);
        }
        AppLogger.i('Splash: session restored for ${vendor.name}');
        Get.offAllNamed(Routes.dashboard);
      },
    );
  }
}