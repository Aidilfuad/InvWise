import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/profile_service.dart';
import '../../services/user_settings_service.dart';
import '../constants/app_colors.dart';

class AppThemeController extends ChangeNotifier with WidgetsBindingObserver {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  final ProfileService _profileService = ProfileService();
  final UserSettingsService _settingsService = UserSettingsService();
  StreamSubscription<AuthState>? _authSubscription;
  ThemeMode _themeMode = ThemeMode.system;
  String _languageCode = 'en';
  String? _errorMessage;
  String? _loadingAuthUserId;
  int _loadGeneration = 0;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      _onAuthStateChanged,
      onError: (Object error) {
        debugPrint('[AppThemeController] Auth state listener failed: $error');
      },
    );

    if (Supabase.instance.client.auth.currentUser != null) {
      await _loadThemeForCurrentUser();
    } else {
      _applyEffectivePalette();
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      final profile = await _profileService.getCurrentProfile();
      if (profile == null) {
        throw const UserSettingsServiceException(
          'Sign in to save your theme preference.',
        );
      }
      await _settingsService.saveThemeMode(
        profileId: profile.id,
        themeMode: themeMode,
      );
      _themeMode = themeMode;
      _errorMessage = null;
      _applyEffectivePalette();
      notifyListeners();
    } catch (error) {
      _errorMessage = _errorText(error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setLanguageCode(String languageCode) async {
    try {
      final profile = await _profileService.getCurrentProfile();
      if (profile == null) {
        throw const UserSettingsServiceException(
          'Sign in to save your language preference.',
        );
      }
      await _settingsService.saveLanguageCode(
        profileId: profile.id,
        languageCode: languageCode,
      );
      _languageCode = languageCode;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = _errorText(error);
      notifyListeners();
      rethrow;
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (_themeMode == ThemeMode.system) {
      _applyEffectivePalette();
      notifyListeners();
    }
  }

  void _onAuthStateChanged(AuthState authState) {
    switch (authState.event) {
      case AuthChangeEvent.signedOut:
        _loadGeneration++;
        _loadingAuthUserId = null;
        _themeMode = ThemeMode.system;
        _languageCode = 'en';
        _errorMessage = null;
        _applyEffectivePalette();
        notifyListeners();
        break;
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.initialSession:
        unawaited(_loadThemeForCurrentUser());
        break;
      default:
        break;
    }
  }

  Future<void> _loadThemeForCurrentUser() async {
    final authUserId = Supabase.instance.client.auth.currentUser?.id;
    if (authUserId == null || _loadingAuthUserId == authUserId) return;

    _loadingAuthUserId = authUserId;
    final generation = ++_loadGeneration;
    try {
      final profile = await _profileService.getCurrentProfile();
      if (profile == null) {
        throw const UserSettingsServiceException(
          'No profile is linked to the signed-in user.',
        );
      }
      final savedMode = await _settingsService.loadOrCreateThemeMode(
        profile.id,
      );
      final savedLanguage = await _settingsService.loadOrCreateLanguageCode(
        profile.id,
      );
      if (generation != _loadGeneration) return;
      _themeMode = savedMode;
      _languageCode = savedLanguage;
      _errorMessage = null;
    } catch (error) {
      if (generation != _loadGeneration) return;
      _themeMode = ThemeMode.system;
      _languageCode = 'en';
      _errorMessage = _errorText(error);
      debugPrint('[AppThemeController] Unable to load theme: $error');
    } finally {
      if (generation == _loadGeneration) {
        _loadingAuthUserId = null;
        _applyEffectivePalette();
        notifyListeners();
      }
    }
  }

  String _errorText(Object error) {
    if (error is ProfileServiceException) {
      return error.message;
    }
    if (error is UserSettingsServiceException) {
      return error.message;
    }
    return 'Unable to load or save theme settings. Please try again.';
  }

  void _applyEffectivePalette() {
    final isDark = switch (_themeMode) {
      ThemeMode.light => false,
      ThemeMode.dark => true,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark,
    };
    AppColors.setDarkMode(isDark);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}
