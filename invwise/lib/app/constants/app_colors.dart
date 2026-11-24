import 'package:flutter/material.dart';

/// Central color palette for InvWise.
///
/// Never hard-code colors in widgets. Use these constants or, preferably,
/// `Theme.of(context).colorScheme` so the UI stays theme-aware.
abstract final class AppColors {
  static bool _isDarkMode = false;

  static void setDarkMode(bool value) {
    _isDarkMode = value;
  }

  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static Color get primaryContainer =>
      _isDarkMode ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);
  static Color get onPrimaryContainer =>
      _isDarkMode ? const Color(0xFFDBEAFE) : const Color(0xFF1E3A8A);

  static const Color secondary = Color(0xFF60A5FA);
  static Color get secondaryContainer =>
      _isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF);
  static Color get onSecondaryContainer =>
      _isDarkMode ? const Color(0xFFBFDBFE) : const Color(0xFF1E40AF);

  // ── Surfaces ───────────────────────────────────────────────────────────
  static Color get background =>
      _isDarkMode ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);
  static Color get surface =>
      _isDarkMode ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
  static Color get surfaceVariant =>
      _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9);

  // ── Text ───────────────────────────────────────────────────────────────
  static Color get textPrimary =>
      _isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  static Color get textSecondary =>
      _isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
  static Color get textDisabled =>
      _isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders & dividers ─────────────────────────────────────────────────
  static Color get border =>
      _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  static Color get borderStrong =>
      _isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
  static Color get divider => border;

  // ── Semantic / status ──────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color onSuccessContainer = Color(0xFF166534);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF92400E);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerContainer = Color(0xFFFEE2E2);
  static const Color onDangerContainer = Color(0xFF991B1B);

  static const Color info = Color(0xFF3B82F6);

  // ── Misc ───────────────────────────────────────────────────────────────
  static Color get shadow =>
      _isDarkMode ? const Color(0x44000000) : const Color(0x140F172A);
  static Color get scrim =>
      _isDarkMode ? const Color(0xB3000000) : const Color(0x990F172A);
}
