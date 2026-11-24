import 'package:flutter/material.dart';

class AuthenticatedPageRouteObserver extends NavigatorObserver {
  AuthenticatedPageRouteObserver({required bool initialAuthenticationRoute})
    : isAuthenticationRoute = ValueNotifier<bool>(initialAuthenticationRoute);

  final ValueNotifier<bool> isAuthenticationRoute;

  static const Set<String> _authenticationRoutes = {
    '/login',
    '/register',
    '/registration-setup',
  };

  static const Set<String> _applicationRoutes = {
    '/registration-approvals',
    '/dashboard',
    '/user-management',
    '/activity-logs',
    '/system/version',
    '/settings/backup',
  };

  bool _routeIsAuthentication(Route<dynamic> route, bool fallback) {
    final name = route.settings.name;
    if (name == null) return fallback;
    if (_authenticationRoutes.contains(name)) return true;
    if (_applicationRoutes.contains(name)) return false;
    return fallback;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    isAuthenticationRoute.value = _routeIsAuthentication(
      route,
      isAuthenticationRoute.value,
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      isAuthenticationRoute.value = _routeIsAuthentication(
        previousRoute,
        isAuthenticationRoute.value,
      );
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      isAuthenticationRoute.value = _routeIsAuthentication(
        newRoute,
        oldRoute == null
            ? isAuthenticationRoute.value
            : _routeIsAuthentication(oldRoute, isAuthenticationRoute.value),
      );
    }
  }

  void dispose() => isAuthenticationRoute.dispose();
}

class AuthenticatedPageLayout extends StatelessWidget {
  const AuthenticatedPageLayout({super.key, required this.child});

  final Widget child;

  static const double maxContentWidth = 1600;
  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1200;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontalPadding = constraints.maxWidth < mobileBreakpoint
          ? 12.0
          : constraints.maxWidth < desktopBreakpoint
          ? 20.0
          : 32.0;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: child,
          ),
        ),
      );
    },
  );
}
