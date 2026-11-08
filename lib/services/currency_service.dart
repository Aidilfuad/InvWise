import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'role_access_service.dart';
import 'profile_service.dart';
import 'user_settings_service.dart';
import 'offline_cache_service.dart';
import 'system_activity_log_service.dart';

enum DisplayCurrency {
  myr('MYR', 'Malaysian Ringgit', 'RM', ' '),
  usd('USD', 'US Dollar', r'$', '');

  const DisplayCurrency(this.code, this.name, this.symbol, this.separator);

  final String code;
  final String name;
  final String symbol;
  final String separator;

  static DisplayCurrency parse(String code) => switch (code) {
    'MYR' => DisplayCurrency.myr,
    'USD' => DisplayCurrency.usd,
    _ => throw CurrencyServiceException(
      'The selected currency is not supported: $code',
    ),
  };
}

class CurrencyServiceException implements Exception {
  const CurrencyServiceException(this.message);

  final String message;

  @override
  String toString() => 'CurrencyServiceException: $message';
}

class CurrencyService extends ChangeNotifier {
  CurrencyService({
    SupabaseClient? client,
    UserSettingsService? userSettingsService,
    RoleAccessService? roleAccessService,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _client = client ?? Supabase.instance.client,
       _userSettingsService = userSettingsService ?? UserSettingsService(),
       _roleAccessService = roleAccessService ?? RoleAccessService.instance;

  static final CurrencyService instance = CurrencyService();

  static const double defaultExchangeRateUsdMyr = 4.25;
  static const String _settingsTable = 'app_settings';
  static const String _exchangeRateSettingId = 'exchange_rate_usd_myr';

  final SupabaseClient _client;
  final UserSettingsService _userSettingsService;
  final RoleAccessService _roleAccessService;
  final Duration requestTimeout;
  late final SystemActivityLogService _activityLog = SystemActivityLogService(
    client: _client,
  );

  DisplayCurrency _displayCurrency = DisplayCurrency.myr;
  double _exchangeRateUsdMyr = defaultExchangeRateUsdMyr;
  String? _loadedProfileId;
  bool _isLoading = false;
  String? _errorMessage;

  DisplayCurrency get displayCurrency => _displayCurrency;
  String get currencyCode => _displayCurrency.code;
  double get exchangeRateUsdMyr => _exchangeRateUsdMyr;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadForProfile(String profileId, {bool refresh = false}) async {
    if (profileId.trim().isEmpty) {
      throw const CurrencyServiceException('A valid profile is required.');
    }
    if (!refresh && _loadedProfileId == profileId && _errorMessage == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final currencyCode = await _userSettingsService.loadOrCreateCurrencyCode(
        profileId,
      );
      final exchangeRate = await _loadExchangeRate();
      _displayCurrency = DisplayCurrency.parse(currencyCode);
      _exchangeRateUsdMyr = exchangeRate;
      _loadedProfileId = profileId;
    } catch (error) {
      _displayCurrency = DisplayCurrency.myr;
      _exchangeRateUsdMyr = defaultExchangeRateUsdMyr;
      _loadedProfileId = profileId;
      _errorMessage = switch (error) {
        UserSettingsServiceException() => error.message,
        CurrencyServiceException() => error.message,
        _ => 'Unable to load currency settings: $error',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadForCurrentUser({bool refresh = false}) async {
    if (_client.auth.currentUser == null) return;
    final profile = await ProfileService().getCurrentProfile();
    if (profile == null) {
      throw const CurrencyServiceException(
        'No profile is linked to the signed-in user.',
      );
    }
    await loadForProfile(profile.id, refresh: refresh);
  }

  Future<void> setDisplayCurrency({
    required String profileId,
    required DisplayCurrency currency,
  }) async {
    _requirePermission(AppPermission.changeDisplayCurrency);
    try {
      await _userSettingsService.saveCurrencyCode(
        profileId: profileId,
        currencyCode: currency.code,
      );
      _displayCurrency = currency;
      _loadedProfileId = profileId;
      _errorMessage = null;
      notifyListeners();
    } on UserSettingsServiceException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setExchangeRateUsdMyr(double rate) async {
    _requirePermission(AppPermission.manageExchangeRate);
    if (!rate.isFinite || rate <= 0) {
      throw const CurrencyServiceException(
        'Exchange rate must be a number greater than zero.',
      );
    }

    await OfflineCacheService.instance.writeValue(
      'settings.exchange_rate_usd_myr',
      rate,
      scopeId: 'global',
    );
    await OfflineCacheService.instance.writeValue(
      'settings.exchange_rate_usd_myr.pending',
      rate,
      scopeId: 'global',
    );
    try {
      final rows = await _client
          .from(_settingsTable)
          .update({
            'exchange_rate_usd_myr': rate,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', _exchangeRateSettingId)
          .select('exchange_rate_usd_myr')
          .timeout(
            requestTimeout,
            onTimeout: () => throw CurrencyServiceException(
              'Saving the exchange rate timed out. Check your connection and '
              'try again. The local value is queued for retry.',
            ),
          );
      if (rows.isEmpty) {
        throw const CurrencyServiceException(
          'Exchange rate setting was not found. Apply the currency settings '
          'database migration and try again.',
        );
      }
      _exchangeRateUsdMyr = _parseRate(rows.first['exchange_rate_usd_myr']);
      await OfflineCacheService.instance.remove(
        'settings.exchange_rate_usd_myr.pending',
        scopeId: 'global',
      );
      _errorMessage = null;
      notifyListeners();
      try {
        await _activityLog.record(
          category: 'Exchange Rate',
          action: 'Updated exchange rate',
          description: '1 USD = ${_exchangeRateUsdMyr.toStringAsFixed(4)} MYR.',
          entityType: 'app_setting',
          entityId: _exchangeRateSettingId,
          metadata: {'exchange_rate_usd_myr': _exchangeRateUsdMyr},
        );
      } catch (error) {
        debugPrint('[CurrencyService] Unable to record rate change: $error');
      }
    } on CurrencyServiceException catch (error) {
      _exchangeRateUsdMyr = rate;
      _errorMessage = error.message;
      OfflineCacheService.instance.recordOfflineError(error.message);
      notifyListeners();
      rethrow;
    } on PostgrestException catch (error) {
      final message = error.code == '42501'
          ? 'You do not have permission to update the exchange rate.'
          : 'Unable to save the exchange rate. ${error.message}';
      _exchangeRateUsdMyr = rate;
      _errorMessage = message;
      OfflineCacheService.instance.recordOfflineError(message);
      notifyListeners();
      throw CurrencyServiceException(message);
    } catch (error) {
      _exchangeRateUsdMyr = rate;
      final message =
          'Unable to save the exchange rate. The local value is queued for '
          'retry: $error';
      _errorMessage = message;
      OfflineCacheService.instance.recordOfflineError(message);
      notifyListeners();
      throw CurrencyServiceException(message);
    }
  }

  Future<double> _loadExchangeRate() => OfflineCacheService.instance.loadValue(
    key: 'settings.exchange_rate_usd_myr',
    scopeId: 'global',
    decode: _parseRate,
    encode: (rate) => rate,
    fetchRemote: _fetchExchangeRate,
  );

  String formatMyr(double amountMyr) {
    if (!amountMyr.isFinite) {
      throw const CurrencyServiceException(
        'Cannot format a non-finite currency amount.',
      );
    }
    final amount = _displayCurrency == DisplayCurrency.myr
        ? amountMyr
        : amountMyr / _exchangeRateUsdMyr;
    final formatted = amount
        .abs()
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    final sign = amount < 0 ? '-' : '';
    return '$sign${_displayCurrency.symbol}${_displayCurrency.separator}'
        '$formatted';
  }

  void _requirePermission(AppPermission permission) {
    if (!_roleAccessService.allows(permission)) {
      throw const CurrencyServiceException(
        'You do not have permission to change this currency setting.',
      );
    }
  }

  Future<double> _fetchExchangeRate() async {
    try {
      final pending = await OfflineCacheService.instance.readValue(
        'settings.exchange_rate_usd_myr.pending',
        scopeId: 'global',
      );
      if (pending != null) {
        final rate = _parseRate(pending);
        final updated = await _client
            .from(_settingsTable)
            .update({
              'exchange_rate_usd_myr': rate,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', _exchangeRateSettingId)
            .select('id');
        if (updated.isEmpty) {
          throw const CurrencyServiceException(
            'Exchange rate setting was not found. The local value remains '
            'queued for a later sync.',
          );
        }
        await OfflineCacheService.instance.remove(
          'settings.exchange_rate_usd_myr.pending',
          scopeId: 'global',
        );
      }
      final row = await _client
          .from(_settingsTable)
          .select('exchange_rate_usd_myr')
          .eq('id', _exchangeRateSettingId)
          .single();
      return _parseRate(row['exchange_rate_usd_myr']);
    } on PostgrestException catch (error) {
      throw CurrencyServiceException(
        'Unable to load exchange rate. ${error.message}',
      );
    }
  }

  double _parseRate(Object? value) {
    final rate = value is num ? value.toDouble() : double.tryParse('$value');
    if (rate == null || !rate.isFinite || rate <= 0) {
      throw const CurrencyServiceException(
        'The saved exchange rate must be greater than zero.',
      );
    }
    return rate;
  }
}
