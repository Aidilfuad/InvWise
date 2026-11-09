import 'dart:convert';

import 'package:flutter/material.dart';

import 'currency_service.dart';
import 'login_preferences_service.dart';
import 'profile_service.dart';
import 'role_access_service.dart';
import 'sensor_monitoring_service.dart';
import 'system_activity_log_service.dart';
import '../app/theme/app_theme_controller.dart';

class SettingsBackupService {
  SettingsBackupService({
    CurrencyService? currencyService,
    SensorMonitoringService? telemetryService,
    SystemActivityLogService? activityLog,
  }) : _currency = currencyService ?? CurrencyService.instance,
       _telemetry = telemetryService ?? SensorMonitoringService(),
       _activityLog = activityLog ?? SystemActivityLogService();

  final CurrencyService _currency;
  final SensorMonitoringService _telemetry;
  final SystemActivityLogService _activityLog;

  Future<String> exportJson() async {
    final profile = await ProfileService().getCurrentProfile();
    if (profile == null) throw StateError('A user profile is required.');
    await _currency.loadForProfile(profile.id, refresh: true);
    final telemetry = await _telemetry.fetchSettings();
    final snapshot = {
      'format': 'invwise-settings',
      'schema_version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'settings': {
        'currency_code': _currency.currencyCode,
        'exchange_rate_usd_myr': _currency.exchangeRateUsdMyr,
        'telemetry': telemetry.toMap(),
        'user_preferences': {
          'theme_mode': AppThemeController.instance.themeMode.name,
          'language_code': AppThemeController.instance.languageCode,
          'remember_me': LoginPreferencesService.instance.rememberMe,
        },
      },
    };
    await _record('Export Settings', 'Exported application settings.');
    return const JsonEncoder.withIndent('  ').convert(snapshot);
  }

  Future<void> importJson(String source) async {
    final decoded = jsonDecode(source);
    if (decoded is! Map ||
        decoded['format'] != 'invwise-settings' ||
        decoded['schema_version'] != 1 ||
        decoded['settings'] is! Map) {
      throw const FormatException(
        'This is not a supported InvWise settings backup.',
      );
    }
    final settings = Map<String, dynamic>.from(decoded['settings'] as Map);
    final profile = await ProfileService().getCurrentProfile();
    if (profile == null) throw StateError('A user profile is required.');

    final currencyCode = settings['currency_code'];
    if (currencyCode is String) {
      await _currency.setDisplayCurrency(
        profileId: profile.id,
        currency: DisplayCurrency.parse(currencyCode),
      );
    }
    final exchangeRate = settings['exchange_rate_usd_myr'];
    if (exchangeRate is num &&
        RoleAccessService.instance.allows(AppPermission.manageExchangeRate)) {
      await _currency.setExchangeRateUsdMyr(exchangeRate.toDouble());
    }
    final telemetry = settings['telemetry'];
    if (telemetry is Map) {
      await _telemetry.saveSettings(
        TelemetrySettings.fromMap(Map<String, dynamic>.from(telemetry)),
      );
    }
    final preferences = settings['user_preferences'];
    if (preferences is Map) {
      final values = Map<String, dynamic>.from(preferences);
      final theme = ThemeMode.values
          .where((mode) => mode.name == values['theme_mode'])
          .firstOrNull;
      if (theme != null) {
        if (AppThemeController.instance.themeMode != theme) {
          await AppThemeController.instance.setThemeMode(theme);
        }
      }
      final language = values['language_code'];
      if (language is String) {
        await AppThemeController.instance.setLanguageCode(language);
      }
      if (values['remember_me'] is bool) {
        await LoginPreferencesService.instance.setRememberMe(
          values['remember_me'] as bool,
        );
      }
    }
    await _record('Import Settings', 'Imported application settings.');
  }

  Future<void> restoreDefaults() async {
    final profile = await ProfileService().getCurrentProfile();
    if (profile == null) throw StateError('A user profile is required.');
    await _currency.setDisplayCurrency(
      profileId: profile.id,
      currency: DisplayCurrency.myr,
    );
    if (RoleAccessService.instance.allows(AppPermission.manageExchangeRate)) {
      await _currency.setExchangeRateUsdMyr(
        CurrencyService.defaultExchangeRateUsdMyr,
      );
    }
    await _telemetry.saveSettings(const TelemetrySettings());
    await AppThemeController.instance.setThemeMode(ThemeMode.system);
    await AppThemeController.instance.setLanguageCode('en');
    await LoginPreferencesService.instance.setRememberMe(false);
    await _record('Restore Settings', 'Restored default application settings.');
  }

  Future<void> _record(String action, String description) async {
    try {
      await _activityLog.record(
        category: 'Settings',
        action: action,
        description: description,
        entityType: 'user_settings',
      );
    } catch (error) {
      throw StateError(
        '$action completed, but its audit record failed: $error',
      );
    }
  }
}
