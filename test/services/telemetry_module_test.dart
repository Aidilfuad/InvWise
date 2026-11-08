import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invwise/services/report_export_service.dart';
import 'package:invwise/services/reports_service.dart';
import 'package:invwise/services/sensor_monitoring_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'analytics computes daily power and cumulative energy metrics',
    () async {
      final service = _service(
        MockClient((request) async {
          if (request.url.path.endsWith('/energy_readings')) {
            expect(
              request.url.queryParameters['order'],
              'recorded_at.asc.nullslast',
            );
            return _jsonResponse([
              _energyRow(power: 100, energy: 10, at: '2026-11-09T01:00:00Z'),
              _energyRow(power: 200, energy: 12, at: '2026-11-09T02:00:00Z'),
              _energyRow(power: 150, energy: 15, at: '2026-11-09T03:00:00Z'),
            ], request);
          }
          return _unexpected(request);
        }),
      );

      final analytics = await service.fetchAnalytics(
        'meter-1',
        now: DateTime(2026, 11, 9, 4),
      );

      expect(analytics.currentPower, 150);
      expect(analytics.currentEnergy, 15);
      expect(analytics.dailyAveragePower, 150);
      expect(analytics.peakPowerToday, 200);
      expect(analytics.lowestPowerToday, 100);
      expect(analytics.energyConsumedToday, 5);
      expect(analytics.estimatedMonthlyConsumption, 150);
    },
  );

  test('telemetry settings round-trip supported values', () async {
    Map<String, dynamic> persisted = {
      'id': 'default',
      'voltage_warning_threshold': 250,
      'current_warning_threshold': 10,
      'offline_timeout_minutes': 5,
      'realtime_enabled': true,
    };
    final service = _service(
      MockClient((request) async {
        if (request.url.path.endsWith('/telemetry_settings')) {
          if (request.method == 'GET') return _jsonResponse(persisted, request);
          if (request.method == 'POST') {
            persisted = Map<String, dynamic>.from(
              jsonDecode(request.body) as Map,
            );
            return http.Response('', 204, request: request);
          }
        }
        return _unexpected(request);
      }),
    );
    const settings = TelemetrySettings(
      voltageWarningThreshold: 245,
      currentWarningThreshold: 8.5,
      offlineTimeoutMinutes: 7,
      realtimeEnabled: false,
    );

    await service.saveSettings(settings);
    final restored = await service.fetchSettings();

    expect(restored.voltageWarningThreshold, 245);
    expect(restored.currentWarningThreshold, 8.5);
    expect(restored.offlineTimeoutMinutes, 7);
    expect(restored.realtimeEnabled, isFalse);
  });

  test(
    'alert evaluation stores voltage and current threshold breaches',
    () async {
      final insertedAlerts = <Map<String, dynamic>>[];
      final service = _service(
        MockClient((request) async {
          if (request.url.path.endsWith('/telemetry_settings')) {
            return _jsonResponse({
              'id': 'default',
              'voltage_warning_threshold': 230,
              'current_warning_threshold': 4,
              'offline_timeout_minutes': 5,
              'realtime_enabled': false,
            }, request);
          }
          if (request.url.path.endsWith('/sensor_alerts') &&
              request.method == 'GET') {
            return _jsonResponse([], request);
          }
          if (request.url.path.endsWith('/sensor_alerts') &&
              request.method == 'POST') {
            final body = jsonDecode(request.body);
            if (body is List) {
              insertedAlerts.addAll(body.cast<Map<String, dynamic>>());
            }
            return http.Response('', 204, request: request);
          }
          return _unexpected(request);
        }),
      );
      final reading = SensorReading(
        sensorId: 'meter-1',
        sensorCode: 'DDS669_01',
        sensorName: 'DDS669',
        sensorType: 'energy_meter',
        valueNumeric: 1224,
        valueText: 'V: 240V, I: 5.1A, E: 1450.25kWh',
        lastSeen: DateTime.now(),
      );

      await service.evaluateAlerts([reading]);

      expect(
        insertedAlerts.map((alert) => alert['alert_type']),
        containsAll(['high_voltage', 'high_current']),
      );
      expect(
        insertedAlerts.every((alert) => alert['status'] == 'active'),
        isTrue,
      );
    },
  );

  test('energy CSV uses quoted cells and embedded quote escaping', () {
    const report = ReportTable(
      title: 'Telemetry',
      headers: ['Sensor', 'State'],
      rows: [
        ['Switch, 1', 'Said "ON"'],
      ],
      metrics: [],
    );

    final csv = utf8.decode(const ReportExportService().toCsv(report));
    expect(csv, contains('"Switch, 1"'));
    expect(csv, contains('"Said ""ON"""'));
  });
}

SensorMonitoringService _service(http.Client client) => SensorMonitoringService(
  client: SupabaseClient(
    'http://localhost:54321',
    'test-key',
    httpClient: client,
    authOptions: FlutterAuthClientOptions(
      autoRefreshToken: false,
      persistSession: false,
      localStorage: const EmptyLocalStorage(),
    ),
  ),
);

http.Response _jsonResponse(Object body, http.Request request) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
  request: request,
);

http.Response _unexpected(http.Request request) => http.Response(
  jsonEncode({'message': 'Unexpected request ${request.url}'}),
  500,
  headers: {'content-type': 'application/json'},
  request: request,
);

Map<String, Object> _energyRow({
  required num power,
  required num energy,
  required String at,
}) => {
  'voltage': 240,
  'current': 5.1,
  'power': power,
  'energy': energy,
  'recorded_at': at,
};
