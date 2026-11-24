import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'offline_cache_service.dart';

class UserSettingsServiceException implements Exception {
  const UserSettingsServiceException(this.message);

  final String message;

  @override
  String toString() => 'UserSettingsServiceException: $message';
}

class UserSettingsService {
  UserSettingsService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const String _table = 'user_settings';
  static const String _defaultLanguageCode = 'en';
  static const String _defaultCurrencyCode = 'MYR';

  final SupabaseClient _client;

  Future<String> loadOrCreateCurrencyCode(String profileId) =>
      OfflineCacheService.instance.loadValue(
        key: 'settings.currency_code',
        scopeId: profileId,
        decode: (value) => _parseCurrencyCode(value),
        encode: (currencyCode) => currencyCode,
        fetchRemote: () => _fetchOrCreateCurrencyCode(profileId),
      );

  Future<String> _fetchOrCreateCurrencyCode(String profileId) async {
    try {
      await _syncPendingSettings(profileId);
      final row = await _client
          .from(_table)
          .select('currency_code')
          .eq('profile_id', profileId)
          .maybeSingle();
      if (row != null) return _parseCurrencyCode(row['currency_code']);

      final now = DateTime.now().toUtc().toIso8601String();
      final createdRow = await _client
          .from(_table)
          .insert({
            'profile_id': profileId,
            'language_code': _defaultLanguageCode,
            'theme_mode': 'system',
            'currency_code': _defaultCurrencyCode,
            'created_at': now,
            'updated_at': now,
          })
          .select('currency_code')
          .single();
      return _parseCurrencyCode(createdRow['currency_code']);
    } on PostgrestException catch (error) {
      if (error.code == '23505') return _loadCurrencyCode(profileId);
      throw UserSettingsServiceException(
        'Unable to load currency preference. ${error.message}',
      );
    }
  }

  Future<void> saveCurrencyCode({
    required String profileId,
    required String currencyCode,
  }) async {
    final selectedCurrency = _parseCurrencyCode(currencyCode);
    await OfflineCacheService.instance.writeValue(
      'settings.currency_code',
      selectedCurrency,
      scopeId: profileId,
    );
    await OfflineCacheService.instance.writeValue(
      'settings.currency_code.pending',
      selectedCurrency,
      scopeId: profileId,
    );
    try {
      await _syncPendingSettings(profileId);
    } catch (error) {
      OfflineCacheService.instance.recordOfflineError(
        'Currency preference is saved on this device and will sync when '
        'a connection is available: $error',
      );
    }
  }

  Future<ThemeMode> loadOrCreateThemeMode(String profileId) =>
      OfflineCacheService.instance.loadValue(
        key: 'settings.theme_mode',
        scopeId: profileId,
        decode: _parseThemeMode,
        encode: _themeModeValue,
        fetchRemote: () => _fetchOrCreateThemeMode(profileId),
      );

  Future<ThemeMode> _fetchOrCreateThemeMode(String profileId) async {
    try {
      await _syncPendingSettings(profileId);
      final row = await _client
          .from(_table)
          .select('theme_mode,currency_code')
          .eq('profile_id', profileId)
          .maybeSingle();
      if (row != null) {
        return _parseThemeMode(row['theme_mode']);
      }

      final now = DateTime.now().toUtc().toIso8601String();
      final createdRow = await _client
          .from(_table)
          .insert({
            'profile_id': profileId,
            'language_code': _defaultLanguageCode,
            'theme_mode': 'system',
            'currency_code': _defaultCurrencyCode,
            'created_at': now,
            'updated_at': now,
          })
          .select('theme_mode')
          .single();
      return _parseThemeMode(createdRow['theme_mode']);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        return _loadThemeMode(profileId);
      }
      throw UserSettingsServiceException(
        'Unable to load theme preference. ${error.message}',
      );
    }
  }

  Future<String> loadOrCreateLanguageCode(String profileId) =>
      OfflineCacheService.instance.loadValue(
        key: 'settings.language_code',
        scopeId: profileId,
        decode: _parseLanguageCode,
        encode: (code) => code,
        fetchRemote: () => _fetchOrCreateLanguageCode(profileId),
      );

  Future<String> _fetchOrCreateLanguageCode(String profileId) async {
    try {
      await _syncPendingSettings(profileId);
      final row = await _client
          .from(_table)
          .select('language_code,currency_code')
          .eq('profile_id', profileId)
          .maybeSingle();
      if (row != null) {
        return _parseLanguageCode(row['language_code']);
      }

      final now = DateTime.now().toUtc().toIso8601String();
      final createdRow = await _client
          .from(_table)
          .insert({
            'profile_id': profileId,
            'language_code': _defaultLanguageCode,
            'theme_mode': 'system',
            'currency_code': _defaultCurrencyCode,
            'created_at': now,
            'updated_at': now,
          })
          .select('language_code')
          .single();
      return _parseLanguageCode(createdRow['language_code']);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        return _loadLanguageCode(profileId);
      }
      throw UserSettingsServiceException(
        'Unable to load language preference. ${error.message}',
      );
    }
  }

  Future<void> saveThemeMode({
    required String profileId,
    required ThemeMode themeMode,
  }) async {
    final mode = _themeModeValue(themeMode);
    await OfflineCacheService.instance.writeValue(
      'settings.theme_mode',
      mode,
      scopeId: profileId,
    );
    await OfflineCacheService.instance.writeValue(
      'settings.theme_mode.pending',
      mode,
      scopeId: profileId,
    );
    try {
      await _syncPendingSettings(profileId);
    } catch (error) {
      OfflineCacheService.instance.recordOfflineError(
        'Theme preference is saved on this device and will sync when a '
        'connection is available: $error',
      );
    }
  }

  Future<void> saveLanguageCode({
    required String profileId,
    required String languageCode,
  }) async {
    final selectedLanguage = _parseLanguageCode(languageCode);
    await OfflineCacheService.instance.writeValue(
      'settings.language_code',
      selectedLanguage,
      scopeId: profileId,
    );
    await OfflineCacheService.instance.writeValue(
      'settings.language_code.pending',
      selectedLanguage,
      scopeId: profileId,
    );
    try {
      await _syncPendingSettings(profileId);
    } catch (error) {
      OfflineCacheService.instance.recordOfflineError(
        'Language preference is saved on this device and will sync when a '
        'connection is available: $error',
      );
    }
  }

  Future<void> _syncPendingSettings(String profileId) async {
    final cache = OfflineCacheService.instance;
    final currency = await cache.readValue(
      'settings.currency_code.pending',
      scopeId: profileId,
    );
    final theme = await cache.readValue(
      'settings.theme_mode.pending',
      scopeId: profileId,
    );
    final language = await cache.readValue(
      'settings.language_code.pending',
      scopeId: profileId,
    );
    if (currency == null && theme == null && language == null) return;

    final existingRow = await _client
        .from(_table)
        .select('language_code,theme_mode,currency_code,created_at')
        .eq('profile_id', profileId)
        .maybeSingle();
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from(_table).upsert({
      'profile_id': profileId,
      'language_code':
          language ?? existingRow?['language_code'] ?? _defaultLanguageCode,
      'theme_mode': theme ?? existingRow?['theme_mode'] ?? 'system',
      'currency_code':
          currency ?? existingRow?['currency_code'] ?? _defaultCurrencyCode,
      'created_at': existingRow?['created_at'] ?? now,
      'updated_at': now,
    }, onConflict: 'profile_id');
    for (final key in [
      'settings.currency_code.pending',
      'settings.theme_mode.pending',
      'settings.language_code.pending',
    ]) {
      await cache.remove(key, scopeId: profileId);
    }
  }

  Future<ThemeMode> _loadThemeMode(String profileId) async {
    try {
      final row = await _client
          .from(_table)
          .select('theme_mode')
          .eq('profile_id', profileId)
          .single();
      return _parseThemeMode(row['theme_mode']);
    } on PostgrestException catch (error) {
      throw UserSettingsServiceException(
        'Unable to load the saved theme preference. ${error.message}',
      );
    }
  }

  Future<String> _loadLanguageCode(String profileId) async {
    try {
      final row = await _client
          .from(_table)
          .select('language_code')
          .eq('profile_id', profileId)
          .single();
      return _parseLanguageCode(row['language_code']);
    } on PostgrestException catch (error) {
      throw UserSettingsServiceException(
        'Unable to load the saved language preference. ${error.message}',
      );
    }
  }

  Future<String> _loadCurrencyCode(String profileId) async {
    try {
      final row = await _client
          .from(_table)
          .select('currency_code')
          .eq('profile_id', profileId)
          .single();
      return _parseCurrencyCode(row['currency_code']);
    } on PostgrestException catch (error) {
      throw UserSettingsServiceException(
        'Unable to load the saved currency preference. ${error.message}',
      );
    }
  }

  ThemeMode _parseThemeMode(Object? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => throw UserSettingsServiceException(
        'The saved theme preference is not supported: $value',
      ),
    };
  }

  String _themeModeValue(ThemeMode themeMode) {
    return switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  String _parseLanguageCode(Object? value) {
    return switch (value) {
      'en' => 'en',
      'ms' => 'ms',
      _ => throw UserSettingsServiceException(
        'The saved language preference is not supported: $value',
      ),
    };
  }

  String _parseCurrencyCode(Object? value) {
    return switch (value) {
      'MYR' => 'MYR',
      'USD' => 'USD',
      _ => throw UserSettingsServiceException(
        'The saved currency preference is not supported: $value',
      ),
    };
  }
}
