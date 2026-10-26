import 'package:flutter/material.dart';

import '../../features/auth/login_page.dart';
import '../../features/dashboard/dashboard_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );

      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );
    }
  }
}