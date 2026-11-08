import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/constants/supabase_config.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/app_theme_controller.dart';
import 'app/routes/app_routes.dart';
import 'services/offline_cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  await OfflineCacheService.instance.initialize();

  unawaited(AppThemeController.instance.initialize());
  runApp(const InvWiseApp());
}

class InvWiseApp extends StatefulWidget {
  const InvWiseApp({super.key});

  @override
  State<InvWiseApp> createState() => _InvWiseAppState();
}

class _InvWiseAppState extends State<InvWiseApp> {
  static final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  bool _registrationSetupOpen = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (state.event == AuthChangeEvent.signedOut) {
        _registrationSetupOpen = false;
        return;
      }
      _openRegistrationSetupIfNeeded(state.session?.user);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openRegistrationSetupIfNeeded(Supabase.instance.client.auth.currentUser);
    });
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
        initialRoute: AppRoutes.login,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
