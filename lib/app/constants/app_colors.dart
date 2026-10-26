import 'package:flutter/material.dart';

/// Central color palette for InvWise.
///
/// Never hard-code colors in widgets. Use these constants or, preferably,
/// `Theme.of(context).colorScheme` so the UI stays theme-aware.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color onPrimaryContainer = Color(0xFF1E3A8A);

  static const Color secondary = Color(0xFF60A5FA);
  static const Color secondaryContainer = Color(0xFFEFF6FF);
  static const Color onSecondaryContainer = Color(0xFF1E40AF);

  // ── Surfaces ───────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // ── Text ───────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders & dividers ─────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE2E8F0);

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
  static const Color shadow = Color(0x140F172A); // 8% slate-900
  static const Color scrim = Color(0x990F172A); // 60% slate-900
}
