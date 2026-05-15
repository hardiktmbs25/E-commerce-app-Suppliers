// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────
  static const primary        = Color(0xFF5B4CDA);   // Deep indigo
  static const primaryLight   = Color(0xFF7B6EEA);
  static const primaryDark    = Color(0xFF3D2FB8);
  static const secondary      = Color(0xFF00C896);   // Mint green (success CTA)
  static const accent         = Color(0xFFFF6B35);   // Warm orange (alerts)

  // ── Semantic ─────────────────────────────────────────────────────────
  static const success        = Color(0xFF22C55E);
  static const warning        = Color(0xFFF59E0B);
  static const error          = Color(0xFFEF4444);
  static const info           = Color(0xFF3B82F6);

  // ── Service type colors ───────────────────────────────────────────────
  static const milk           = Color(0xFF9C27B0);
  static const water          = Color(0xFF2196F3);
  static const newspaper      = Color(0xFF795548);
  static const tiffin         = Color(0xFFFF5722);
  static const custom         = Color(0xFF607D8B);

  // ── Neutrals (Light) ─────────────────────────────────────────────────
  static const background     = Color(0xFFF8F9FE);
  static const surface        = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F3FF);
  static const border         = Color(0xFFE8EAF6);
  static const divider        = Color(0xFFEEF0F8);

  // ── Text ─────────────────────────────────────────────────────────────
  static const textPrimary    = Color(0xFF0F172A);
  static const textSecondary  = Color(0xFF64748B);
  static const textHint       = Color(0xFFADB5BD);
  static const textOnPrimary  = Color(0xFFFFFFFF);

  // ── Cards ────────────────────────────────────────────────────────────
  static const cardShadow     = Color(0x14000000);

  // ── Dashboard card gradients ──────────────────────────────────────────
  static const List<Color> gradientPurple = [Color(0xFF5B4CDA), Color(0xFF8B7AFF)];
  static const List<Color> gradientGreen  = [Color(0xFF00C896), Color(0xFF00E5B0)];
  static const List<Color> gradientOrange = [Color(0xFFFF6B35), Color(0xFFFF9068)];
  static const List<Color> gradientBlue   = [Color(0xFF3B82F6), Color(0xFF60A5FA)];
  static const List<Color> gradientRed    = [Color(0xFFEF4444), Color(0xFFF87171)];
  static const List<Color> gradientTeal   = [Color(0xFF14B8A6), Color(0xFF2DD4BF)];
}