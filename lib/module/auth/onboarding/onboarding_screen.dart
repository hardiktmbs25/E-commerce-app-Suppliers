// lib/modules/auth/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import 'onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: controller.pageController,
            onPageChanged: (i) => controller.currentPage.value = i,
            itemCount: controller.pages.length,
            itemBuilder: (_, i) => _OnboardingPage(page: controller.pages[i]),
          ),
          // Skip button
          Positioned(
            top: 56,
            right: 24,
            child: Obx(() => controller.currentPage.value < controller.pages.length - 1
                ? GestureDetector(
              onTap: controller.skip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text('Skip',
                    style: TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ),
            )
                : const SizedBox()),
          ),
          // Bottom controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dots
                  Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(controller.pages.length, (i) {
                      final isActive = i == controller.currentPage.value;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  )),
                  const SizedBox(height: 24),
                  Obx(() {
                    final isLast = controller.currentPage.value == controller.pages.length - 1;
                    return SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: controller.nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          isLast ? 'Get Started' : 'Continue',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: Colors.white, fontFamily: 'Poppins'),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingPage page;
  const _OnboardingPage({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [page.bgColor, page.bgColor.withValues(alpha: 0.7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(page.emoji, style: const TextStyle(fontSize: 64)),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              page.title,
              style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800,
                color: Colors.white, fontFamily: 'Poppins',
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              page.subtitle,
              style: TextStyle(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.85),
                fontFamily: 'Poppins', height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 200),
        ],
      ),
    );
  }
} 