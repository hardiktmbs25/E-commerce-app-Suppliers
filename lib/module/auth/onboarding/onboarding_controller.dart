// lib/modules/auth/onboarding/onboarding_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../services/local_storage_service.dart';

class OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;
  const OnboardingPage({required this.emoji, required this.title, required this.subtitle, required this.bgColor});
}

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  final pages = const [
    OnboardingPage(
      emoji: '📋',
      title: 'Manage All Customers',
      subtitle: 'Add, track and organize all your milk, water, newspaper and tiffin customers in one place.',
      bgColor: Color(0xFF5B4CDA),
    ),
    OnboardingPage(
      emoji: '🚴',
      title: 'Track Deliveries Daily',
      subtitle: 'Mark deliveries as done, missed or pending — even without internet. Sync automatically later.',
      bgColor: Color(0xFF00C896),
    ),
    OnboardingPage(
      emoji: '💰',
      title: 'Auto-Generate Bills',
      subtitle: 'Monthly invoices are calculated automatically. Track payments and get paid faster.',
      bgColor: Color(0xFFFF6B35),
    ),
    OnboardingPage(
      emoji: '📊',
      title: 'Grow Your Business',
      subtitle: 'See revenue analytics, pending payments and customer insights — like a real SaaS dashboard.',
      bgColor: Color(0xFF3B82F6),
    ),
  ];

  void nextPage() {
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      completeOnboarding();
    }
  }

  void skip() => completeOnboarding();

  Future<void> completeOnboarding() async {
    await LocalStorageService.saveSetting('onboarding_done', true);
    Get.offAllNamed(Routes.login);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}