import 'package:flutter/material.dart';

import 'app/theme/app_theme.dart';
import 'app/routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InvWiseApp());
}

class InvWiseApp extends StatelessWidget {
  const InvWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InvWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      // Temporary placeholder. Replace with the router / auth gate later.
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
  
}


