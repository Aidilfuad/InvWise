import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/constants/supabase_config.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/app_theme_controller.dart';
import 'app/routes/app_routes.dart';
import 'services/login_preferences_service.dart';
import 'services/offline_cache_service.dart';
import 'services/app_update_service.dart';
import 'features/settings/widgets/update_available_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  await OfflineCacheService.instance.initialize();
  final shouldOpenDashboard = await LoginPreferencesService.instance
      .prepareForStartup(Supabase.instance.client);

  unawaited(AppThemeController.instance.initialize());
  runApp(InvWiseApp(shouldOpenDashboard: shouldOpenDashboard));
}

class InvWiseApp extends StatefulWidget {
  const InvWiseApp({super.key, required this.shouldOpenDashboard});

  final bool shouldOpenDashboard;

  @override
  State<InvWiseApp> createState() => _InvWiseAppState();
}

class _InvWiseAppState extends State<InvWiseApp> {
  static final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  bool _registrationSetupOpen = false;
  bool _updateCheckStarted = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (state.event == AuthChangeEvent.signedOut) {
        _registrationSetupOpen = false;
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (_) => false,
        );
        return;
      }
      _openRegistrationSetupIfNeeded(state.session?.user);
      if (state.session?.user != null) {
        unawaited(_checkForUpdates());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openRegistrationSetupIfNeeded(Supabase.instance.client.auth.currentUser);
      if (Supabase.instance.client.auth.currentUser != null) {
        unawaited(_checkForUpdates());
      }
    });
  }

  Future<void> _checkForUpdates() async {
    if (_updateCheckStarted) return;
    _updateCheckStarted = true;
    final service = AppUpdateService();
    try {
      final result = await service.checkForUpdates();
      if (!mounted ||
          (result.status != AppUpdateStatus.available &&
              result.status != AppUpdateStatus.required)) {
        return;
      }
      final release = result.release!;
      final context = _navigatorKey.currentContext;
      if (context == null) return;
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: !release.forceUpdate,
        builder: (_) =>
            UpdateAvailableDialog(release: release, service: service),
      );
    } catch (error) {
      debugPrint('App update check failed: $error');
    } finally {
      service.dispose();
    }
  }

  void _openRegistrationSetupIfNeeded(User? user) {
    final requestId = user?.userMetadata?['registration_request_id'];
    if (requestId is! String || requestId.isEmpty || _registrationSetupOpen) {
      return;
    }
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openRegistrationSetupIfNeeded(user);
      });
      return;
    }
    _registrationSetupOpen = true;
    navigator.pushNamedAndRemoveUntil(
      AppRoutes.registrationSetup,
      (_) => false,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, child) => MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'InvWise',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: AppThemeController.instance.themeMode,
        locale: Locale(AppThemeController.instance.languageCode),
        supportedLocales: const [Locale('en'), Locale('ms')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: widget.shouldOpenDashboard
            ? AppRoutes.dashboard
            : AppRoutes.login,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
