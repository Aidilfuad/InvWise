import 'package:flutter/material.dart';

import '../../features/auth/login_page.dart';
import '../../features/auth/registration_approvals_page.dart';
import '../../features/auth/registration_request_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../services/role_access_service.dart';

class AppRoutes {
  static const String login = '/login';
  static const String registrationRequest = '/register';
  static const String registrationApprovals = '/registration-approvals';
  static const String dashboard = '/dashboard';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case registrationRequest:
        return MaterialPageRoute(
          builder: (_) => const RegistrationRequestPage(),
        );

      case registrationApprovals:
        return MaterialPageRoute(
          builder: (_) => const RegistrationApprovalsPage(),
        );

      case dashboard:
        return MaterialPageRoute(
          builder: (_) => RoleAccessGuard(
            permission: AppPermission.viewDashboard,
            child: const DashboardPage(),
          ),
        );

      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}
