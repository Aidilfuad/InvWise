import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invwise/features/dashboard/widgets/sensor_monitoring_card.dart';
import 'package:invwise/services/sensor_monitoring_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sensor presence follows the 2 and 5 minute thresholds', () {
    final now = DateTime(2026, 11, 8, 21);
    SensorReading readingAt(int secondsAgo) => SensorReading(
      sensorId: 'sensor-1',
      sensorCode: 'DDS669_01',
      sensorName: 'Main Energy Meter',
      sensorType: 'energy_meter',
      valueNumeric: 1224,
      valueText: 'V: 240V, I: 5.1A, E: 1450.25kWh',
      lastSeen: now.subtract(Duration(seconds: secondsAgo)),
    );

    expect(readingAt(120).presenceAt(now), SensorPresence.online);
    expect(readingAt(121).presenceAt(now), SensorPresence.warning);
    expect(readingAt(300).presenceAt(now), SensorPresence.warning);
    expect(readingAt(301).presenceAt(now), SensorPresence.offline);
    expect(
      SensorReading(
        sensorId: 'sensor-2',
        sensorCode: 'SW_01',
        sensorName: 'Control Toggle Switch',
        sensorType: 'toggle_switch',
        valueNumeric: 1,
        valueText: 'ON',
        lastSeen: null,
      ).presenceAt(now),
      SensorPresence.offline,
    );
  });

  test('data age formats seconds and minutes and clamps future timestamps', () {
    final now = DateTime.utc(2026, 11, 8, 21);
    SensorReading readingAt(Duration age) => SensorReading(
      sensorId: 'meter',
      sensorCode: 'DDS669_01',
      sensorName: 'Main Energy Meter',
      sensorType: 'energy_meter',
      valueNumeric: 1224,
      valueText: 'V: 240V, I: 5.1A, E: 1450.25kWh',
      lastSeen: now.subtract(age),
    );

    expect(
      readingAt(const Duration(seconds: 5)).updatedLabelAt(now),
      'Updated 5 sec ago',
    );
    expect(
      readingAt(const Duration(minutes: 1)).updatedLabelAt(now),
      'Updated 1 min ago',
    );
    expect(
      readingAt(const Duration(minutes: 3)).updatedLabelAt(now),
      'Updated 3 min ago',
    );
    expect(
      readingAt(const Duration(seconds: -5)).updatedLabelAt(now),
      'Updated 0 sec ago',
    );
  });

  testWidgets('loads joined readings and manual sync refreshes the card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var statusRequestCount = 0;
    var shouldFail = false;
    var now = DateTime(2026, 11, 8, 21, 12, 45);
    final httpClient = MockClient((request) async {
      if (request.url.path.endsWith('/activity_logs')) {
        return http.Response('', 201, request: request);
      }
      if (request.url.path.endsWith('/telemetry_settings')) {
        return http.Response(
          jsonEncode({
            'id': 'default',
            'voltage_warning_threshold': 250,
            'current_warning_threshold': 10,
            'offline_timeout_minutes': 5,
            'realtime_enabled': false,
          }),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }
      if (request.url.path.endsWith('/sensor_alerts')) {
        if (request.method == 'GET') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        return http.Response('', 204, request: request);
      }
      if (request.url.path.endsWith('/energy_readings')) {
        return http.Response(
          jsonEncode([
            {
              'voltage': 240,
              'current': 5.1,
              'power': 1224,
              'energy': 1450.25,
              'recorded_at': now.toUtc().toIso8601String(),
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }
      if (request.url.path.endsWith('/switch_events')) {
        return http.Response(
          jsonEncode([
            {
              'switch_state': 'ON',
              'recorded_at': now.toUtc().toIso8601String(),
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }
      statusRequestCount++;
      expect(request.url.path, '/rest/v1/sensor_status');
      expect(
        request.url.queryParameters['select'],
        contains('sensors(sensor_code,sensor_name,sensor_type)'),
      );
      if (shouldFail) {
        return http.Response(
          jsonEncode({'message': 'network error'}),
          503,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }

      final lastSeen = now
          .toUtc()
          .subtract(const Duration(seconds: 20))
          .toIso8601String();
      return http.Response(
        jsonEncode([
          {
            'sensor_id': 'meter-1',
            'value_numeric': 1224,
            'value_text': 'V: 240V, I: 5.1A, E: 1450.25kWh',
            'last_seen': lastSeen,
            'sensors': {
              'sensor_code': 'DDS669_01',
              'sensor_name': 'Main Energy Meter',
              'sensor_type': 'energy_meter',
            },
          },
          {
            'sensor_id': 'switch-1',
            'value_numeric': 1,
            'value_text': 'ON',
            'last_seen': now
                .toUtc()
                .subtract(const Duration(seconds: 301))
                .toIso8601String(),
            'sensors': {
              'sensor_code': 'SW_01',
              'sensor_name': 'Control Toggle Switch',
              'sensor_type': 'toggle_switch',
            },
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    final client = SupabaseClient(
      'http://localhost:54321',
      'test-key',
      httpClient: httpClient,
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: false,
        persistSession: false,
        localStorage: const EmptyLocalStorage(),
      ),
    );
    final service = SensorMonitoringService(client: client);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SensorMonitoringCard(
              service: service,
              clock: () => now,
              offlineCheckInterval: null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(statusRequestCount, 1);
    expect(find.text('Sensor Monitoring'), findsOneWidget);
    expect(find.text('DDS669'), findsOneWidget);
    expect(find.text('Toggle Switch'), findsOneWidget);
    expect(find.text('Voltage'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Power'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
    expect(find.textContaining('1450.25kWh'), findsOneWidget);
    expect(find.text('ON'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('2 Sensors'), findsOneWidget);
    expect(find.text('1 Online'), findsOneWidget);
    expect(find.text('1 Offline'), findsOneWidget);
    expect(find.text('Updated 20 sec ago'), findsOneWidget);
    expect(find.text('Updated 5 min ago'), findsOneWidget);
    expect(find.text('Last Sync: 9:12:45 PM'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final fullCardHeight = tester
        .getSize(find.byType(SensorMonitoringCard))
        .height;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SensorMonitoringCard(
              service: service,
              clock: () => now,
              offlineCheckInterval: null,
              compact: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final compactCardHeight = tester
        .getSize(find.byType(SensorMonitoringCard))
        .height;
    // ignore: avoid_print
    print(
      'Phone sensor card: full=${fullCardHeight.toStringAsFixed(0)}px, '
      'compact=${compactCardHeight.toStringAsFixed(0)}px, '
      'reduction=${((fullCardHeight - compactCardHeight) / fullCardHeight * 100).toStringAsFixed(1)}%',
    );
    expect(compactCardHeight, lessThan(fullCardHeight * 0.7));
    expect(
      find.textContaining('240V · 5.1A · 1224W · 1450.25kWh'),
      findsOneWidget,
    );
    expect(find.text('Updated 20 sec ago'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SensorMonitoringCard(
              service: service,
              clock: () => now,
              offlineCheckInterval: null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();
    expect(find.text('2 Sensors'), findsOneWidget);
    expect(find.text('50% Health'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1400, 1000);
    await tester.pumpAndSettle();
    expect(find.text('2 Sensors'), findsOneWidget);
    expect(find.text('50% Health'), findsOneWidget);
    expect(tester.takeException(), isNull);

    now = now.add(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('Manual Sync'));
    await tester.pumpAndSettle();

    expect(statusRequestCount, 2);
    expect(find.text('Last Sync: 9:12:46 PM'), findsOneWidget);
    expect(find.text('Sensor data synced successfully'), findsOneWidget);

    shouldFail = true;
    await tester.tap(find.byTooltip('Manual Sync'));
    await tester.pumpAndSettle();

    expect(statusRequestCount, greaterThan(2));
    expect(find.text('Unable to sync sensor data'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('View Details →'));
    await tester.pumpAndSettle();
    expect(find.text('Telemetry Details'), findsOneWidget);
    expect(find.text('Voltage'), findsOneWidget);
    expect(find.text('Last Seen'), findsNWidgets(2));
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('State'), findsOneWidget);

    await tester.tap(find.text('View Telemetry History'));
    await tester.pumpAndSettle();
    expect(find.text('Telemetry History'), findsOneWidget);
    expect(find.text('DDS669 · Latest 20 readings'), findsOneWidget);
    expect(find.text('Voltage Trend'), findsOneWidget);
    expect(find.text('Current Trend'), findsOneWidget);
    expect(find.text('Power Trend'), findsOneWidget);
    expect(find.text('Energy Trend'), findsOneWidget);
    expect(find.text('Last 24 Hours'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Switch · Latest 20 events'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Switch · Latest 20 events'), findsOneWidget);
    expect(find.text('Voltage: 240V'), findsOneWidget);
    expect(find.text('ON'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sensor Monitoring'));
    await tester.pumpAndSettle();
    expect(find.text('Telemetry Details'), findsOneWidget);
    await tester.tap(find.text('Telemetry Analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Telemetry Analytics'), findsOneWidget);
    expect(find.text('Current Power'), findsOneWidget);
    expect(find.text('Daily Average Power'), findsOneWidget);
    await tester.tap(find.text('Energy Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Energy Reports'), findsOneWidget);
    expect(find.text("Today's Usage"), findsOneWidget);
  });

  testWidgets('initial telemetry failure exposes a retry action', (
    tester,
  ) async {
    var requestCount = 0;
    var shouldFail = true;
    final client = SupabaseClient(
      'http://localhost:54321',
      'test-key',
      httpClient: MockClient((request) async {
        requestCount++;
        if (request.url.path.endsWith('/telemetry_settings')) {
          return http.Response(
            jsonEncode({
              'id': 'default',
              'voltage_warning_threshold': 250,
              'current_warning_threshold': 10,
              'offline_timeout_minutes': 5,
              'realtime_enabled': false,
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.url.path.endsWith('/sensor_alerts')) {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (shouldFail) {
          return http.Response(
            jsonEncode({'message': 'network error'}),
            503,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        return http.Response(
          jsonEncode(_sensorRows(DateTime.utc(2026, 11, 8, 21))),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: false,
        persistSession: false,
        localStorage: const EmptyLocalStorage(),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SensorMonitoringCard(
            service: SensorMonitoringService(client: client),
            clock: () => DateTime.utc(2026, 11, 8, 21),
            offlineCheckInterval: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestCount, greaterThan(1));
    expect(find.text('Unable to load telemetry data'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('No sensor data available'), findsNothing);

    shouldFail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(requestCount, greaterThan(2));
    expect(find.text('DDS669'), findsOneWidget);
    expect(find.text('Unable to load telemetry data'), findsNothing);
  });

  testWidgets('manual sync disables the button and prevents duplicate calls', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 8, 21);
    var requestCount = 0;
    late http.Request pendingRequest;
    final pendingSync = Completer<http.Response>();
    final client = SupabaseClient(
      'http://localhost:54321',
      'test-key',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/telemetry_settings')) {
          return http.Response(
            jsonEncode({
              'id': 'default',
              'voltage_warning_threshold': 250,
              'current_warning_threshold': 10,
              'offline_timeout_minutes': 5,
              'realtime_enabled': false,
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.url.path.endsWith('/sensor_alerts')) {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.url.path.endsWith('/activity_logs')) {
          return http.Response('', 201, request: request);
        }
        requestCount++;
        if (requestCount == 1) {
          return http.Response(
            jsonEncode(_sensorRows(now)),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        pendingRequest = request;
        return pendingSync.future;
      }),
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: false,
        persistSession: false,
        localStorage: const EmptyLocalStorage(),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SensorMonitoringCard(
            service: SensorMonitoringService(client: client),
            clock: () => now,
            offlineCheckInterval: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requestCount, 1);

    now = now.add(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('Manual Sync'));
    await tester.pump();
    expect(requestCount, 2);
    final syncingButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(syncingButton.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byTooltip('Manual Sync'));
    await tester.pump();
    expect(requestCount, 2);

    pendingSync.complete(
      http.Response(
        jsonEncode(_sensorRows(now)),
        200,
        headers: {'content-type': 'application/json'},
        request: pendingRequest,
      ),
    );
    await tester.pumpAndSettle();
    expect(requestCount, 2);
    expect(find.text('Sensor data synced successfully'), findsOneWidget);
  });

  testWidgets('monitoring card shows configured meter and toggle only', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 8, 21, 12);
    final client = SupabaseClient(
      'http://localhost:54321',
      'test-key',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/telemetry_settings')) {
          return http.Response(
            jsonEncode({
              'id': 'default',
              'voltage_warning_threshold': 250,
              'current_warning_threshold': 10,
              'offline_timeout_minutes': 5,
              'realtime_enabled': false,
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.url.path.endsWith('/sensor_alerts')) {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.url.path.endsWith('/activity_logs')) {
          return http.Response('', 201, request: request);
        }
        expect(request.url.path, '/rest/v1/sensor_status');
        return http.Response(
          jsonEncode(_sensorRows(now, includeIriv: true)),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: false,
        persistSession: false,
        localStorage: const EmptyLocalStorage(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SensorMonitoringCard(
              service: SensorMonitoringService(client: client),
              clock: () => now,
              offlineCheckInterval: null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DDS669'), findsOneWidget);
    expect(find.text('Voltage'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Power'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
    expect(find.text('Toggle Switch'), findsOneWidget);
    expect(find.text('ON'), findsOneWidget);
    expect(find.text('2 Sensors'), findsOneWidget);
    expect(find.text('Receiving Bay IRIV'), findsNothing);
    expect(find.text('IRIV Sensors'), findsNothing);
    expect(find.text('Proximity Sensor'), findsNothing);
    expect(find.text('Trigger Count'), findsNothing);
    expect(find.text('Receipt Count'), findsNothing);
    expect(find.text('Last Detection'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

List<Map<String, dynamic>> _sensorRows(
  DateTime now, {
  bool includeIriv = false,
}) {
  final lastSeen = now.toUtc().toIso8601String();
  return [
    {
      'sensor_id': 'meter-1',
      'value_numeric': 1224,
      'value_text': 'V: 240V, I: 5.1A, E: 1450.25kWh',
      'last_seen': lastSeen,
      'sensors': {
        'sensor_code': 'DDS669_01',
        'sensor_name': 'Main Energy Meter',
        'sensor_type': 'energy_meter',
      },
    },
    {
      'sensor_id': 'switch-1',
      'value_numeric': 1,
      'value_text': 'ON',
      'last_seen': lastSeen,
      'sensors': {
        'sensor_code': 'SW_01',
        'sensor_name': 'Control Toggle Switch',
        'sensor_type': 'toggle_switch',
      },
    },
    if (includeIriv)
      {
        'sensor_id': 'iriv-1',
        'value_numeric': null,
        'value_text': '{"trigger_count":7,"receipt_count":15}',
        'last_seen': lastSeen,
        'sensors': {
          'sensor_code': 'IRIV_01',
          'sensor_name': 'Receiving Bay IRIV',
          'sensor_type': 'iriv',
        },
      },
    if (includeIriv)
      {
        'sensor_id': 'proximity-1',
        'value_numeric': 1,
        'value_text': 'Detected',
        'last_seen': lastSeen,
        'sensors': {
          'sensor_code': 'PROX_01',
          'sensor_name': 'Proximity Sensor',
          'sensor_type': 'proximity',
        },
      },
  ];
}
