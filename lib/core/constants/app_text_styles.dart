// lib/core/constants/app_text_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  static const String _font = 'Poppins';

  // ── Display ──────────────────────────────────────────────────────────
  static const displayLarge = TextStyle(
    fontFamily: _font, fontSize: 32, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.2,
  );
  static const displayMedium = TextStyle(
    fontFamily: _font, fontSize: 26, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3, height: 1.3,
  );

  // ── Headline ─────────────────────────────────────────────────────────
  static const headlineLarge = TextStyle(
    fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );
  static const headlineMedium = TextStyle(
    fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.4,
  );
  static const headlineSmall = TextStyle(
    fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.4,
  );

  // ── Body ─────────────────────────────────────────────────────────────
  static const bodyLarge = TextStyle(
    fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.6,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.6,
  );
  static const bodySmall = TextStyle(
    fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );

  // ── Label ────────────────────────────────────────────────────────────
  static const labelLarge = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.1,
  );
  static const labelMedium = TextStyle(
    fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 0.2,
  );
  static const labelSmall = TextStyle(
    fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w600,
    color: AppColors.textHint, letterSpacing: 0.4,
  );

  // ── Button ───────────────────────────────────────────────────────────
  static const buttonLarge = TextStyle(
    fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w700,
    color: Colors.white, letterSpacing: 0.3,
  );
  static const buttonMedium = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w600,
    color: Colors.white, letterSpacing: 0.2,
  );

  // ── Amount/Numbers ───────────────────────────────────────────────────
  static const amountLarge = TextStyle(
    fontFamily: _font, fontSize: 28, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static const amountMedium = TextStyle(
    fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
  static const amountSmall = TextStyle(
    fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}