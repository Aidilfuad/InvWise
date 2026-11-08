import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<String> loadOrCreateCurrencyCode(String profileId) async {
    try {
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
    try {
      final existingRow = await _client
          .from(_table)
          .select('language_code,theme_mode,created_at')
          .eq('profile_id', profileId)
          .maybeSingle();
      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from(_table).upsert({
        'profile_id': profileId,
        'language_code':
            existingRow?['language_code'] ?? _defaultLanguageCode,
        'theme_mode': existingRow?['theme_mode'] ?? 'system',
        'currency_code': selectedCurrency,
        'created_at': existingRow?['created_at'] ?? now,
        'updated_at': now,
      }, onConflict: 'profile_id');
    } on PostgrestException catch (error) {
      throw UserSettingsServiceException(
        'Unable to save currency preference. ${error.message}',
      );
    }
  }

  Future<ThemeMode> loadOrCreateThemeMode(String profileId) async {
    try {
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

  Future<String> loadOrCreateLanguageCode(String profileId) async {
    try {
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
    try {
      final existingRow = await _client
          .from(_table)
          .select('language_code,currency_code,created_at')
          .eq('profile_id', profileId)
          .maybeSingle();

      final now = DateTime.now().toUtc().toIso8601String();
      final payload = <String, dynamic>{
        'profile_id': profileId,
        'language_code': existingRow?['language_code'] ?? _defaultLanguageCode,
        'currency_code':
            existingRow?['currency_code'] ?? _defaultCurrencyCode,
        'theme_mode': _themeModeValue(themeMode),
        'created_at': existingRow?['created_at'] ?? now,
        'updated_at': now,
      };

      await _client.from(_table).upsert(payload, onConflict: 'profile_id');
    } on PostgrestException catch (error) {
      throw UserSettingsServiceException(
        'Unable to save theme preference. ${error.message}',
      );
    }
  }

  Future<void> saveLanguageCode({
    required String profileId,
    required String languageCode,
  }) async {
    final selectedLanguage = _parseLanguageCode(languageCode);
    try {
      final existingRow = await _client
          .from(_table)
          .select('theme_mode,currency_code,created_at')
          .eq('profile_id', profileId)
          .maybeSingle();

      final now = DateTime.now().toUtc().toIso8601String();
      final payload = <String, dynamic>{
        'profile_id': profileId,
        'language_code': selectedLanguage,
        'theme_mode': existingRow?['theme_mode'] ?? 'system',
        'currency_code':
            existingRow?['currency_code'] ?? _defaultCurrencyCode,
        'created_at': existingRow?['created_at'] ?? now,
        'updated_at': now,
      };

      await _client.from(_table).upsert(payload, onConflict: 'profile_id');
    } on PostgrestException catch (error) {
      throw UserSettingsServiceException(
        'Unable to save language preference. ${error.message}',
      );
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
