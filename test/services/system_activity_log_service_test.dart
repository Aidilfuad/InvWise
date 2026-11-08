import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invwise/features/activity_log/activity_logs_page.dart';
import 'package:invwise/services/system_activity_log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('writes open-ended audit records with entity metadata', () async {
    http.Request? insertedRequest;
    final client = _client(
      MockClient((request) async {
        if (request.url.path.endsWith('/activity_logs')) {
          insertedRequest = request;
          return http.Response('', 201, request: request);
        }
        return http.Response('[]', 200, request: request);
      }),
    );
    final service = SystemActivityLogService(client: client);

    await service.record(
      category: 'Inventory Receiving Voucher',
      action: 'Received goods',
      description: 'Voucher IRIV-0001 received.',
      entityType: 'inventory_receiving_voucher',
      entityId: 'IRIV-0001',
      metadata: {'lines': 3},
    );

    final body = jsonDecode(insertedRequest!.body) as Map<String, dynamic>;
    expect(body['category'], 'Inventory Receiving Voucher');
    expect(body['entity_type'], 'inventory_receiving_voucher');
    expect(body['entity_id'], 'IRIV-0001');
    expect(body['metadata'], {'lines': 3});
  });

  test(
    'reads newest-first audit rows and parses extensible categories',
    () async {
      final client = _client(
        MockClient((request) async {
          expect(request.url.path, endsWith('/activity_logs'));
          expect(
            request.url.queryParameters['order'],
            'occurred_at.desc.nullslast,id.desc.nullslast',
          );
          expect(request.url.queryParameters['limit'], '5');
          return http.Response(
            jsonEncode([
              {
                'id': 'log-1',
                'actor_name': 'Aidil',
                'category': 'Registration Approvals',
                'action': 'Changed role',
                'description': 'Storekeeper → Supervisor',
                'occurred_at': '2026-11-09T01:00:00Z',
                'entity_type': 'profile',
                'entity_id': 'profile-1',
                'metadata': {'old_role': 'Storekeeper'},
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );

      final entries = await SystemActivityLogService(client: client)
          .getLatest(limit: 5);

      expect(entries, hasLength(1));
      expect(entries.single.actorName, 'Aidil');
      expect(entries.single.category, 'Registration Approvals');
      expect(entries.single.action, 'Changed role');
      expect(entries.single.metadata['old_role'], 'Storekeeper');
    },
  );

  test('activity queries apply category and inclusive date filters', () async {
    final client = _client(
      MockClient((request) async {
        expect(request.url.queryParameters['category'], 'eq.Telemetry');
        final dateFilters = request.url.queryParametersAll['occurred_at']!;
        expect(dateFilters, hasLength(2));
        expect(dateFilters.any((value) => value.startsWith('gte.')), isTrue);
        expect(dateFilters.any((value) => value.startsWith('lt.')), isTrue);
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );

    await SystemActivityLogService(client: client).getEntries(
      category: 'Telemetry',
      from: DateTime(2026, 11, 9),
      through: DateTime(2026, 11, 9),
    );
  });

  testWidgets('activity viewer search and filters fit a phone layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = SystemActivityLogService(
      client: _client(
        MockClient((request) async {
          return http.Response(
            jsonEncode([
              {
                'id': 'log-1',
                'actor_name': 'Aidil',
                'category': 'Registration Approvals',
                'action': 'Changed role',
                'description': 'Storekeeper → Supervisor',
                'occurred_at': '2026-11-09T01:00:00Z',
                'entity_type': 'profile',
                'entity_id': 'profile-1',
                'metadata': const {},
              },
              {
                'id': 'log-2',
                'actor_name': 'System',
                'category': 'Telemetry',
                'action': 'Sensor Offline',
                'description': 'Main meter is offline.',
                'occurred_at': '2026-11-09T01:10:00Z',
                'entity_type': 'sensor_alert',
                'entity_id': 'sensor-1',
                'metadata': const {},
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: ActivityLogsPage(service: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activity Logs'), findsOneWidget);
    expect(find.text('Changed role'), findsOneWidget);
    expect(find.text('Registration Approvals'), findsOneWidget);
    expect(find.text('User'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField).first, 'Aidil');
    await tester.pumpAndSettle();
    expect(find.text('Changed role'), findsOneWidget);
    expect(find.text('Sensor Offline'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Main meter');
    await tester.pumpAndSettle();
    expect(find.text('Main meter is offline.'), findsOneWidget);
    expect(find.text('Changed role'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Telemetry').last);
    await tester.pumpAndSettle();
    expect(find.text('Sensor Offline'), findsOneWidget);
    expect(find.text('Changed role'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'not in the log');
    await tester.pumpAndSettle();
    expect(find.text('No activity logs found.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(900, 1000);
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Category'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1400, 1000);
    await tester.pumpAndSettle();
    expect(find.text('Category'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

SupabaseClient _client(http.Client httpClient) => SupabaseClient(
  'http://localhost:54321',
  'test-key',
  httpClient: httpClient,
  authOptions: FlutterAuthClientOptions(
    autoRefreshToken: false,
    persistSession: false,
    localStorage: const EmptyLocalStorage(),
  ),
);
