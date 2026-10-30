import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/constants/supabase_config.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/app_theme_controller.dart';
import 'app/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  unawaited(AppThemeController.instance.initialize());
  runApp(const InvWiseApp());
}

class InvWiseApp extends StatelessWidget {
  const InvWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, child) => MaterialApp(
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