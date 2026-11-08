import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'offline_cache_service.dart';

class LoginPreferencesService extends ChangeNotifier {
  LoginPreferencesService._();

  static final LoginPreferencesService instance = LoginPreferencesService._();

  static const String _rememberMeKey = 'auth.remember_me';
  static const String _emailKey = 'auth.remembered_email';
  static const String _employeeIdKey = 'auth.remembered_employee_id';

  bool _rememberMe = false;
  String? _rememberedEmail;
  String? _rememberedEmployeeId;

  bool get rememberMe => _rememberMe;
  String? get rememberedEmail => _rememberedEmail;
  String? get rememberedEmployeeId => _rememberedEmployeeId;

  Future<void> initialize() async {
    final cache = OfflineCacheService.instance;
    _rememberMe =
        await cache.readValue(_rememberMeKey, scopeId: 'global') == true;
    _rememberedEmail =
        await cache.readValue(_emailKey, scopeId: 'global') as String?;
    _rememberedEmployeeId =
        await cache.readValue(_employeeIdKey, scopeId: 'global') as String?;
    if (!_rememberMe) {
      _rememberedEmail = null;
      _rememberedEmployeeId = null;
    }
    notifyListeners();
  }

  Future<bool> prepareForStartup(SupabaseClient client) async {
    await initialize();
    final session = client.auth.currentSession;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (shouldRestoreSession(
      rememberMe: _rememberMe,
      expiresAt: session?.expiresAt,
      nowSeconds: nowSeconds,
    )) {
      return true;
    }
    if (session != null) {
      await client.auth.signOut(scope: SignOutScope.local);
    }
    return false;
  }

  static bool shouldRestoreSession({
    required bool rememberMe,
    required int? expiresAt,
    required int nowSeconds,
  }) => rememberMe && expiresAt != null && expiresAt > nowSeconds;

  Future<void> setRememberMe(bool enabled) async {
    await OfflineCacheService.instance.writeValue(
      _rememberMeKey,
      enabled,
      scopeId: 'global',
    );
    _rememberMe = enabled;
    if (!enabled) {
      await clearStoredIdentity();
    }
    notifyListeners();
  }

  Future<void> rememberLogin({
    required String email,
    required bool enabled,
    String? employeeId,
  }) async {
    await setRememberMe(enabled);
    if (!enabled) return;
    final cache = OfflineCacheService.instance;
    final normalizedEmail = email.trim();
    if (normalizedEmail.isNotEmpty) {
      await cache.writeValue(_emailKey, normalizedEmail, scopeId: 'global');
      _rememberedEmail = normalizedEmail;
    }
    final normalizedEmployeeId = employeeId?.trim();
    if (normalizedEmployeeId?.isNotEmpty == true) {
      await cache.writeValue(
        _employeeIdKey,
        normalizedEmployeeId!,
        scopeId: 'global',
      );
      _rememberedEmployeeId = normalizedEmployeeId;
    }
    notifyListeners();
  }

  Future<void> clearStoredIdentity() async {
    final cache = OfflineCacheService.instance;
    await cache.remove(_emailKey, scopeId: 'global');
    await cache.remove(_employeeIdKey, scopeId: 'global');
    _rememberedEmail = null;
    _rememberedEmployeeId = null;
  }
}
