import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// Global Material 3 theme for InvWise.
///
/// Usage: `MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark)`.
abstract final class AppTheme {
  // ── Color scheme ───────────────────────────────────────────────────────
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    primaryContainer: Color(0xFFDBEAFE),
    onPrimaryContainer: Color(0xFF1E3A8A),
    secondary: AppColors.secondary,
    onSecondary: Color(0xFF0F172A),
    secondaryContainer: Color(0xFFEFF6FF),
    onSecondaryContainer: Color(0xFF1E40AF),
    tertiary: AppColors.success,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.successContainer,
    onTertiaryContainer: AppColors.onSuccessContainer,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerContainer,
    onErrorContainer: AppColors.onDangerContainer,
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0F172A),
    onSurfaceVariant: Color(0xFF64748B),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8FAFC),
    surfaceContainer: Color(0xFFF1F5F9),
    surfaceContainerHigh: Color(0xFFF1F5F9),
    surfaceContainerHighest: Color(0xFFE2E8F0),
    outline: Color(0xFFCBD5E1),
    outlineVariant: Color(0xFFE2E8F0),
    shadow: Color(0x140F172A),
    scrim: Color(0x990F172A),
    inverseSurface: Color(0xFF0F172A),
    onInverseSurface: Color(0xFFFFFFFF),
    inversePrimary: AppColors.secondary,
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    primaryContainer: Color(0xFF1E3A8A),
    onPrimaryContainer: Color(0xFFDBEAFE),
    secondary: AppColors.secondary,
    onSecondary: Color(0xFF0F172A),
    secondaryContainer: Color(0xFF1E3A5F),
    onSecondaryContainer: Color(0xFFBFDBFE),
    tertiary: Color(0xFF4ADE80),
    onTertiary: Color(0xFF052E16),
    tertiaryContainer: Color(0xFF14532D),
    onTertiaryContainer: Color(0xFFDCFCE7),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF111827),
    onSurface: Color(0xFFF1F5F9),
    onSurfaceVariant: Color(0xFFCBD5E1),
    surfaceContainerLowest: Color(0xFF0B1220),
    surfaceContainerLow: Color(0xFF0B1220),
    surfaceContainer: Color(0xFF1F2937),
    surfaceContainerHigh: Color(0xFF273449),
    surfaceContainerHighest: Color(0xFF334155),
    outline: Color(0xFF475569),
    outlineVariant: Color(0xFF334155),
    shadow: Colors.black,
    scrim: Color(0xB3000000),
    inverseSurface: Color(0xFFE2E8F0),
    onInverseSurface: Color(0xFF0F172A),
    inversePrimary: Color(0xFF2563EB),
    surfaceTint: Colors.transparent,
  );

  static ThemeData get light => _buildTheme(_lightScheme);
  static ThemeData get dark => _buildTheme(_darkScheme);

  // ── Typography ─────────────────────────────────────────────────────────
  static TextTheme _textTheme(ColorScheme scheme) {
    final base = Typography.material2021().black.apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.5),
      bodySmall: base.bodySmall?.copyWith(
        height: 1.4,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: base.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  // ── Theme builder ──────────────────────────────────────────────────────
  static ThemeData _buildTheme(ColorScheme scheme) {
    final textTheme = _textTheme(scheme);

    const buttonShape = RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMd,
    );
    const buttonSize = Size.fromHeight(AppSpacing.buttonHeight);

    OutlineInputBorder inputBorder(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      canvasColor: scheme.surface,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      dividerColor: scheme.outlineVariant,

      // App bar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: scheme.surfaceContainerLow,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface),
        systemOverlayStyle:
            (scheme.brightness == Brightness.dark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark)
                .copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonSize,
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          foregroundColor: AppColors.primary,
          side: BorderSide(color: scheme.outline),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        hintStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle:
            textTheme.bodySmall?.copyWith(color: AppColors.primary),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.danger),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: inputBorder(scheme.outlineVariant),
        enabledBorder: inputBorder(scheme.outlineVariant),
        focusedBorder: inputBorder(AppColors.primary, width: 1.5),
        errorBorder: inputBorder(AppColors.danger),
        focusedErrorBorder: inputBorder(AppColors.danger, width: 1.5),
        disabledBorder: inputBorder(scheme.outlineVariant),
      ),

      // Navigation
      navigationBarTheme: NavigationBarThemeData(
        height: AppSpacing.navBarHeight,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: AppSpacing.iconMd,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelMedium,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),

      // Dialogs, sheets, snackbars
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
      ),

      // Lists, dividers, misc
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: scheme.primaryContainer,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : scheme.onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : scheme.outlineVariant),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
