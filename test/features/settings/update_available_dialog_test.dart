import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invwise/features/settings/widgets/update_available_dialog.dart';
import 'package:invwise/services/app_update_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('optional update can be dismissed with Later', (tester) async {
    final service = _service(opened: true);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => UpdateAvailableDialog(
                  release: _release(),
                  service: service,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Later'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateAvailableDialog), findsNothing);
    service.dispose();
  });

  testWidgets('forced update hides Later and blocks back dismissal', (
    tester,
  ) async {
    final service = _service(opened: true);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => UpdateAvailableDialog(
                  release: _release(forceUpdate: true),
                  service: service,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Update Required'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    expect(find.byTooltip('Close update dialog'), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateAvailableDialog), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(UpdateAvailableDialog), findsOneWidget);

    await tester.tap(find.text('Update Now'));
    await tester.pumpAndSettle();
    expect(find.text('✓ Download Started'), findsOneWidget);
    expect(
      find.text(
        'Update download started. Complete installation and reopen InvWise.',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Close update dialog'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(UpdateAvailableDialog), findsNothing);
    service.dispose();
  });

  testWidgets('forced update remains locked when URL launch fails', (
    tester,
  ) async {
    final service = _service(opened: false);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => UpdateAvailableDialog(
                  release: _release(forceUpdate: true),
                  service: service,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update Now'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Unable to open update'), findsOneWidget);
    expect(find.byTooltip('Close update dialog'), findsNothing);
    expect(find.text('Update Now'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(UpdateAvailableDialog), findsOneWidget);
    service.dispose();
  });
}

AppUpdateService _service({required bool opened}) => AppUpdateService(
  client: SupabaseClient(
    'http://localhost:54321',
    'test-key',
    httpClient: MockClient(
      (request) async => http.Response(
        request.url.path.endsWith('/activity_logs') ? '' : jsonEncode([]),
        request.url.path.endsWith('/activity_logs') ? 201 : 200,
        headers: {'content-type': 'application/json'},
        request: request,
      ),
    ),
    authOptions: FlutterAuthClientOptions(
      autoRefreshToken: false,
      persistSession: false,
      localStorage: const EmptyLocalStorage(),
    ),
  ),
  urlLauncher: (url, mode) async => opened,
);

AppVersionRelease _release({bool forceUpdate = false}) => AppVersionRelease(
  version: '1.0.1',
  apkUrl: 'https://downloads.example/app.apk',
  releaseNotes: 'Update validation',
  forceUpdate: forceUpdate,
  createdAt: DateTime.utc(2026, 11, 9),
);
