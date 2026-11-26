import 'dart:async';

import 'package:app_links/app_links.dart';
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
import 'widgets/authenticated_page_layout.dart';

const _authCallbackParameterNames = {
  'access_token',
  'refresh_token',
  'code',
  'token_hash',
  'type',
  'error',
  'error_code',
  'error_description',
};

Map<String, String> _authLinkParameters(Uri uri) {
  try {
    return {
      ...uri.queryParameters,
      ...Uri.splitQueryString(uri.fragment),
    };
  } on FormatException {
    return uri.queryParameters;
  }
}

bool _isAuthCallbackUri(Uri uri) =>
    _authLinkParameters(uri).keys.any(_authCallbackParameterNames.contains);

String? _authLinkType(Uri uri) {
  final type = _authLinkParameters(uri)['type'];
  return type == 'invite' || type == 'recovery' ? type : null;
}

String _authLinkErrorMessage(Object error) {
  final message = error is AuthException
      ? error.message
      : error.toString().replaceFirst('Exception: ', '');
  if (RegExp(r'expired|invalid|already been used|otp', caseSensitive: false)
      .hasMatch(message)) {
    return 'This invite or password link is invalid, expired, or has already been used. Ask your InvWise administrator for a new invite or request another password reset.';
  }
  return message;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appLinks = AppLinks();
  Uri? initialAuthLink;
  try {
    initialAuthLink = await appLinks.getInitialLink();
  } catch (error) {
    debugPrint('Unable to read the initial authentication link: $error');
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
  );
  final initialAuthType = initialAuthLink == null
      ? null
      : _authLinkType(initialAuthLink);
  String? initialAuthError;
  var authLinkEstablishedSession = false;
  if (initialAuthLink != null && _isAuthCallbackUri(initialAuthLink)) {
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(initialAuthLink);
      authLinkEstablishedSession =
          Supabase.instance.client.auth.currentSession != null;
    } catch (error) {
      initialAuthError = _authLinkErrorMessage(error);
    }
  }
  await OfflineCacheService.instance.initialize();
  final shouldOpenDashboard = await LoginPreferencesService.instance
      .prepareForStartup(
        Supabase.instance.client,
        preserveSession: authLinkEstablishedSession,
      );

  unawaited(AppThemeController.instance.initialize());
  runApp(
    InvWiseApp(
      shouldOpenDashboard: shouldOpenDashboard,
      appLinks: appLinks,
      initialAuthError: initialAuthError,
      initialAuthType: initialAuthType,
    ),
  );
}

class InvWiseApp extends StatefulWidget {
  const InvWiseApp({
    super.key,
    required this.shouldOpenDashboard,
    required this.appLinks,
    this.initialAuthError,
    this.initialAuthType,
  });

  final bool shouldOpenDashboard;
  final AppLinks appLinks;
  final String? initialAuthError;
  final String? initialAuthType;

  @override
  State<InvWiseApp> createState() => _InvWiseAppState();
}

class _InvWiseAppState extends State<InvWiseApp> {
  static final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;
  bool _registrationSetupOpen = false;
  bool _updateCheckStarted = false;
  late final AuthenticatedPageRouteObserver _routeObserver =
      AuthenticatedPageRouteObserver(
        initialAuthenticationRoute: !widget.shouldOpenDashboard,
      );

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (state.event == AuthChangeEvent.signedOut) {
        final setupWillNavigate = _registrationSetupOpen;
        _registrationSetupOpen = false;
        if (!setupWillNavigate) {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRoutes.login,
            (_) => false,
          );
        }
        return;
      }
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _openPasswordRecovery();
        return;
      }
      _openRegistrationSetupIfNeeded(state.session?.user);
      if (state.session?.user != null) {
        unawaited(_checkForUpdates());
      }
    }, onError: (Object error, StackTrace stackTrace) {
      _showAuthLinkError(_authLinkErrorMessage(error));
    });
    _deepLinkSubscription = widget.appLinks.uriLinkStream.listen(
      (uri) {
        if (_isAuthCallbackUri(uri)) unawaited(_handleAuthLink(uri));
      },
      onError: (Object error, StackTrace stackTrace) {
        _showAuthLinkError(_authLinkErrorMessage(error));
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialAuthError != null) {
        _showAuthLinkError(widget.initialAuthError!);
        return;
      }
      if (widget.initialAuthType == 'recovery') {
        _openPasswordRecovery();
        return;
      }
      _openRegistrationSetupIfNeeded(Supabase.instance.client.auth.currentUser);
      if (Supabase.instance.client.auth.currentUser != null) {
        unawaited(_checkForUpdates());
      }
    });
  }

  Future<void> _handleAuthLink(Uri uri) async {
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (error) {
      _showAuthLinkError(_authLinkErrorMessage(error));
    }
  }

  void _showAuthLinkError(String message) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAuthLinkError(message);
      });
      return;
    }
    navigator.pushNamedAndRemoveUntil(
      AppRoutes.authLinkError,
      (_) => false,
      arguments: message,
    );
  }

  void _openPasswordRecovery() {
    if (_registrationSetupOpen) return;
    if (Supabase.instance.client.auth.currentUser == null) {
      _showAuthLinkError(
        'The password recovery link could not establish a session. Request another password reset.',
      );
      return;
    }
    _registrationSetupOpen = true;
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.registrationSetup,
      (_) => false,
      arguments: true,
    );
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
    _deepLinkSubscription?.cancel();
    _routeObserver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, child) => MaterialApp(
        navigatorKey: _navigatorKey,
        navigatorObservers: [_routeObserver],
        builder: (context, navigator) => ValueListenableBuilder<bool>(
          valueListenable: _routeObserver.isAuthenticationRoute,
          child: navigator,
          builder: (context, isAuthenticationRoute, child) =>
              isAuthenticationRoute
              ? child!
              : AuthenticatedPageLayout(child: child!),
        ),
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
