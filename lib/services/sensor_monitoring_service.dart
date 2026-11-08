import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'system_activity_log_service.dart';

double _asDouble(Object? value, {required double fallback}) {
  if (value is num && value.isFinite) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _asInt(Object? value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}

enum SensorPresence { online, warning, offline }

class EnergyReadingHistory {
  const EnergyReadingHistory({
    required this.voltage,
    required this.current,
    required this.power,
    required this.energy,
    required this.recordedAt,
  });

  final double voltage;
  final double current;
  final double power;
  final double energy;
  final DateTime recordedAt;
}

class SwitchEventHistory {
  const SwitchEventHistory({required this.state, required this.recordedAt});

  final String state;
  final DateTime recordedAt;
}

enum TelemetryPeriod {
  last24Hours('Last 24 Hours', Duration(hours: 24)),
  last7Days('Last 7 Days', Duration(days: 7)),
  last30Days('Last 30 Days', Duration(days: 30));

  const TelemetryPeriod(this.label, this.duration);

  final String label;
  final Duration duration;
}

class TelemetrySettings {
  const TelemetrySettings({
    this.voltageWarningThreshold = 250,
    this.currentWarningThreshold = 10,
    this.offlineTimeoutMinutes = 5,
    this.realtimeEnabled = true,
  });

  final double voltageWarningThreshold;
  final double currentWarningThreshold;
  final int offlineTimeoutMinutes;
  final bool realtimeEnabled;

  factory TelemetrySettings.fromMap(Map<String, dynamic> map) =>
      TelemetrySettings(
        voltageWarningThreshold: _asDouble(
          map['voltage_warning_threshold'],
          fallback: 250,
        ),
        currentWarningThreshold: _asDouble(
          map['current_warning_threshold'],
          fallback: 10,
        ),
        offlineTimeoutMinutes: _asInt(
          map['offline_timeout_minutes'],
          fallback: 5,
        ),
        realtimeEnabled: map['realtime_enabled'] as bool? ?? true,
      );

  Map<String, Object> toMap() => {
    'id': 'default',
    'voltage_warning_threshold': voltageWarningThreshold,
    'current_warning_threshold': currentWarningThreshold,
    'offline_timeout_minutes': offlineTimeoutMinutes,
    'realtime_enabled': realtimeEnabled,
  };
}

class TelemetryAlert {
  const TelemetryAlert({
    required this.id,
    required this.sensorId,
    required this.sensorName,
    required this.alertType,
    required this.severity,
    required this.status,
    required this.message,
    required this.detectedAt,
    required this.dedupeKey,
  });

  final String id;
  final String sensorId;
  final String sensorName;
  final String alertType;
  final String severity;
  final String status;
  final String message;
  final DateTime detectedAt;
  final String dedupeKey;

  factory TelemetryAlert.fromMap(Map<String, dynamic> map) {
    final sensor = map['sensors'];
    return TelemetryAlert(
      id: map['id'] as String,
      sensorId: map['sensor_id'] as String,
      sensorName: sensor is Map
          ? sensor['sensor_name'] as String? ?? 'Sensor'
          : 'Sensor',
      alertType: map['alert_type'] as String,
      severity: map['severity'] as String,
      status: map['status'] as String,
      message: map['message'] as String,
      detectedAt: DateTime.parse(map['detected_at'] as String).toLocal(),
      dedupeKey: map['dedupe_key'] as String,
    );
  }
}

class TelemetryAnalytics {
  const TelemetryAnalytics({
    required this.currentPower,
    required this.currentEnergy,
    required this.dailyAveragePower,
    required this.peakPowerToday,
    required this.lowestPowerToday,
    required this.energyConsumedToday,
    required this.estimatedMonthlyConsumption,
    required this.readings,
  });

  final double currentPower;
  final double currentEnergy;
  final double dailyAveragePower;
  final double peakPowerToday;
  final double lowestPowerToday;
  final double energyConsumedToday;
  final double estimatedMonthlyConsumption;
  final List<EnergyReadingHistory> readings;
}

class TelemetryEnergyReport {
  const TelemetryEnergyReport({
    required this.todayUsage,
    required this.weekUsage,
    required this.monthUsage,
    required this.peakPower,
    required this.highestCurrent,
    required this.lowestVoltage,
  });

  final double todayUsage;
  final double weekUsage;
  final double monthUsage;
  final double peakPower;
  final double highestCurrent;
  final double lowestVoltage;
}

class SensorReading {
  const SensorReading({
    required this.sensorId,
    required this.sensorCode,
    required this.sensorName,
    required this.sensorType,
    required this.valueNumeric,
    required this.valueText,
    required this.lastSeen,
  });

  final String sensorId;
  final String sensorCode;
  final String sensorName;
  final String sensorType;
  final double? valueNumeric;
  final String? valueText;
  final DateTime? lastSeen;

  double? get voltage => _measurement('V');
  double? get current => _measurement('I');
  double? get energy => _measurement('E');
  double? get power => valueNumeric;

  SensorPresence presenceAt(DateTime now, {int offlineTimeoutMinutes = 5}) {
    final lastSeen = this.lastSeen;
    if (lastSeen == null) return SensorPresence.offline;
    final age = now.difference(lastSeen);
    if (age <= const Duration(minutes: 2)) return SensorPresence.online;
    if (age <= Duration(minutes: offlineTimeoutMinutes)) {
      return SensorPresence.warning;
    }
    return SensorPresence.offline;
  }

  String updatedLabelAt(DateTime now) {
    final lastSeen = this.lastSeen;
    if (lastSeen == null) return 'Last seen time unavailable';
    final seconds = now.difference(lastSeen).inSeconds.clamp(0, 1 << 31);
    if (seconds < 60) return 'Updated $seconds sec ago';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return 'Updated $minutes min ago';
    final hours = minutes ~/ 60;
    if (hours < 24) return 'Updated $hours hr ago';
    return 'Updated ${hours ~/ 24} days ago';
  }

  double? _measurement(String key) {
    final text = valueText;
    if (text == null) return null;
    final match = RegExp(
      '(?:^|[,;\\s])$key\\s*:\\s*([0-9]+(?:\\.[0-9]+)?)',
      caseSensitive: false,
    ).firstMatch(text);
    return match == null ? null : double.tryParse(match.group(1)!);
  }
}

class SensorMonitoringService {
  SensorMonitoringService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  late final SystemActivityLogService _activityLog = SystemActivityLogService(
    client: _client,
  );

  RealtimeChannel subscribeToSensorStatus(void Function() onChange) => _client
      .channel('dashboard-sensor-status')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'sensor_status',
        callback: (_) => onChange(),
      )
      .subscribe();

  Future<void> removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  Future<List<SensorReading>> fetchLatest() async {
    final rows = await _client
        .from('sensor_status')
        .select(
          'sensor_id,value_numeric,value_text,last_seen,'
          'sensors(sensor_code,sensor_name,sensor_type)',
        )
        .order('last_seen', ascending: false);

    final readingsBySensorId = <String, SensorReading>{};
    for (final row in rows) {
      final sensor = row['sensors'];
      if (sensor is! Map) {
        throw const FormatException(
          'Sensor status row is missing its sensor details.',
        );
      }

      final sensorId = row['sensor_id'];
      final sensorCode = sensor['sensor_code'];
      final sensorName = sensor['sensor_name'];
      final sensorType = sensor['sensor_type'];
      if (sensorId is! String ||
          sensorCode is! String ||
          sensorName is! String ||
          sensorType is! String) {
        throw const FormatException(
          'Sensor status row contains invalid sensor details.',
        );
      }
      if (readingsBySensorId.containsKey(sensorId)) continue;

      final lastSeenValue = row['last_seen'];
      final numericValue = row['value_numeric'];
      readingsBySensorId[sensorId] = SensorReading(
        sensorId: sensorId,
        sensorCode: sensorCode,
        sensorName: sensorName,
        sensorType: sensorType.toLowerCase(),
        valueNumeric: numericValue == null ? null : _parseNumber(numericValue),
        valueText: row['value_text'] as String?,
        lastSeen: lastSeenValue == null
            ? null
            : DateTime.tryParse(lastSeenValue as String)?.toLocal(),
      );
    }

    return readingsBySensorId.values.toList(growable: false);
  }

  Future<List<EnergyReadingHistory>> fetchEnergyHistory(String sensorId) async {
    final rows = await _readEnergyRows(
      sensorId: sensorId,
      since: DateTime.fromMillisecondsSinceEpoch(0),
      ascending: false,
      maxRows: 20,
    );
    return rows;
  }

  Future<List<SwitchEventHistory>> fetchSwitchHistory(String sensorId) async {
    final rows = await _client
        .from('switch_events')
        .select('switch_state,recorded_at')
        .eq('sensor_id', sensorId)
        .order('recorded_at', ascending: false)
        .limit(20);
    return rows
        .map((row) {
          final state = row['switch_state'];
          final recordedAt = DateTime.tryParse(row['recorded_at'] as String);
          if (state is! String || recordedAt == null) {
            throw const FormatException(
              'Switch event contains invalid telemetry data.',
            );
          }
          return SwitchEventHistory(
            state: state,
            recordedAt: recordedAt.toLocal(),
          );
        })
        .toList(growable: false);
  }

  Future<List<SwitchEventHistory>> fetchSwitchExport(String sensorId) async {
    final result = <SwitchEventHistory>[];
    const pageSize = 500;
    while (result.length < 5000) {
      final offset = result.length;
      final pageEnd = (offset + pageSize - 1).clamp(0, 4999);
      final rows = await _client
          .from('switch_events')
          .select('switch_state,recorded_at')
          .eq('sensor_id', sensorId)
          .order('recorded_at', ascending: false)
          .range(offset, pageEnd);
      result.addAll(
        rows.map((row) {
          final state = row['switch_state'];
          final recordedAt = DateTime.tryParse(row['recorded_at'] as String);
          if (state is! String || recordedAt == null) {
            throw const FormatException(
              'Switch event contains invalid telemetry data.',
            );
          }
          return SwitchEventHistory(
            state: state,
            recordedAt: recordedAt.toLocal(),
          );
        }),
      );
      if (rows.length < pageSize || result.length >= 5000) break;
    }
    return result;
  }

  Future<List<EnergyReadingHistory>> fetchEnergyExport(String sensorId) =>
      _readEnergyRows(
        sensorId: sensorId,
        since: DateTime.fromMillisecondsSinceEpoch(0),
        ascending: false,
        maxRows: 5000,
      );

  Future<List<EnergyReadingHistory>> fetchEnergyChart(
    String sensorId,
    TelemetryPeriod period, {
    DateTime? now,
  }) async {
    final readings = await _readEnergyRows(
      sensorId: sensorId,
      since: (now ?? DateTime.now()).subtract(period.duration),
      ascending: true,
      maxRows: 2000,
    );
    return readings;
  }

  Future<TelemetryAnalytics> fetchAnalytics(
    String sensorId, {
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final startOfDay = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final readings = await _readEnergyRows(
      sensorId: sensorId,
      since: startOfDay,
      ascending: true,
      maxRows: 2000,
    );
    final current = readings.isEmpty ? null : readings.last;
    final powers = readings.map((reading) => reading.power).toList();
    final usage = _counterDelta(readings);
    return TelemetryAnalytics(
      currentPower: current?.power ?? 0,
      currentEnergy: current?.energy ?? 0,
      dailyAveragePower: _average(powers),
      peakPowerToday: powers.isEmpty ? 0 : powers.reduce(_max),
      lowestPowerToday: powers.isEmpty ? 0 : powers.reduce(_min),
      energyConsumedToday: usage,
      estimatedMonthlyConsumption: usage * 30,
      readings: readings,
    );
  }

  Future<TelemetryEnergyReport> fetchEnergyReport(
    String sensorId, {
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(today.year, today.month);
    final readings = await _readEnergyRows(
      sensorId: sensorId,
      since: monthStart,
      ascending: true,
      maxRows: 5000,
    );
    final todayReadings = readings
        .where((reading) => !reading.recordedAt.isBefore(today))
        .toList();
    final weekReadings = readings
        .where((reading) => !reading.recordedAt.isBefore(weekStart))
        .toList();
    final powers = readings.map((reading) => reading.power).toList();
    final currents = readings.map((reading) => reading.current).toList();
    final voltages = readings.map((reading) => reading.voltage).toList();
    return TelemetryEnergyReport(
      todayUsage: _counterDelta(todayReadings),
      weekUsage: _counterDelta(weekReadings),
      monthUsage: _counterDelta(readings),
      peakPower: powers.isEmpty ? 0 : powers.reduce(_max),
      highestCurrent: currents.isEmpty ? 0 : currents.reduce(_max),
      lowestVoltage: voltages.isEmpty ? 0 : voltages.reduce(_min),
    );
  }

  Future<TelemetrySettings> fetchSettings() async {
    final row = await _client
        .from('telemetry_settings')
        .select()
        .eq('id', 'default')
        .maybeSingle();
    return row == null
        ? const TelemetrySettings()
        : TelemetrySettings.fromMap(row);
  }

  Future<void> saveSettings(TelemetrySettings settings) async {
    await _client.from('telemetry_settings').upsert(settings.toMap());
  }

  Future<void> recordSyncActivity({
    required bool succeeded,
    int? sensorCount,
  }) async {
    try {
      await _activityLog.record(
        category: 'Telemetry',
        action: succeeded ? 'Sensor sync' : 'Sensor sync failed',
        description: succeeded
            ? 'Sensor data synced successfully.'
            : 'Unable to sync sensor data.',
        entityType: 'sensor_sync',
        metadata: {'sensor_count': sensorCount},
      );
    } catch (error) {
      debugPrint(
        '[SensorMonitoringService] Unable to record sync activity: $error',
      );
    }
  }

  Future<List<TelemetryAlert>> fetchAlerts({bool activeOnly = false}) async {
    var query = _client
        .from('sensor_alerts')
        .select(
          'id,sensor_id,alert_type,severity,status,message,detected_at,'
          'dedupe_key,sensors(sensor_name)',
        );
    if (activeOnly) query = query.eq('status', 'active');
    final rows = await query.order('detected_at', ascending: false).limit(500);
    return rows
        .map((row) => TelemetryAlert.fromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<void> evaluateAlerts(List<SensorReading> readings) async {
    final settings = await fetchSettings();
    final now = DateTime.now().toUtc();
    final candidates = <Map<String, Object?>>[];
    for (final reading in readings) {
      final type = reading.sensorType;
      final voltage = reading.voltage;
      if (type == 'energy_meter' &&
          voltage != null &&
          voltage > settings.voltageWarningThreshold) {
        candidates.add(
          _alertPayload(
            reading,
            'high_voltage',
            'warning',
            'High Voltage',
            'Voltage ${voltage}V exceeds ${settings.voltageWarningThreshold}V.',
          ),
        );
      }
      final current = reading.current;
      if (type == 'energy_meter' &&
          current != null &&
          current > settings.currentWarningThreshold) {
        candidates.add(
          _alertPayload(
            reading,
            'high_current',
            'warning',
            'High Current',
            'Current ${current}A exceeds '
                '${settings.currentWarningThreshold}A.',
          ),
        );
      }
      if (reading.presenceAt(
            now.toLocal(),
            offlineTimeoutMinutes: settings.offlineTimeoutMinutes,
          ) ==
          SensorPresence.offline) {
        candidates.add(
          _alertPayload(
            reading,
            'sensor_offline',
            'critical',
            'Sensor Offline',
            '${reading.sensorName} has not reported for '
                '${settings.offlineTimeoutMinutes} minutes.',
          ),
        );
      }
    }

    final active = await fetchAlerts(activeOnly: true);
    final activeKeys = active
        .map((alert) => '${alert.sensorId}:${alert.alertType}')
        .toSet();
    final expectedKeys = candidates.map(_alertKindKey).toSet();
    final newCandidates = candidates
        .where((alert) => !activeKeys.contains(_alertKindKey(alert)))
        .toList(growable: false);
    if (newCandidates.isNotEmpty) {
      await _client
          .from('sensor_alerts')
          .upsert(
            newCandidates,
            onConflict: 'dedupe_key',
            ignoreDuplicates: true,
          );
      for (final candidate in newCandidates) {
        try {
          await _activityLog.record(
            category: 'Telemetry',
            action: candidate['alert_type'] == 'sensor_offline'
                ? 'Sensor Offline'
                : candidate['alert_type'] == 'high_voltage'
                ? 'High Voltage'
                : 'High Current',
            description: candidate['message'] as String,
            entityType: 'sensor_alert',
            entityId: candidate['sensor_id'] as String,
            metadata: {
              'alert_type': candidate['alert_type'],
              'severity': candidate['severity'],
            },
            actorName: 'System',
          );
        } catch (error) {
          debugPrint(
            '[SensorMonitoringService] Unable to record alert activity: '
            '$error',
          );
        }
      }
    }
    final staleIds = active
        .where(
          (alert) =>
              !expectedKeys.contains('${alert.sensorId}:${alert.alertType}'),
        )
        .map((alert) => alert.id)
        .toList(growable: false);
    if (staleIds.isNotEmpty) {
      await _client
          .from('sensor_alerts')
          .update({'status': 'resolved', 'resolved_at': now.toIso8601String()})
          .inFilter('id', staleIds);
    }
  }

  Map<String, Object?> _alertPayload(
    SensorReading reading,
    String type,
    String severity,
    String title,
    String message,
  ) {
    final now = DateTime.now().toUtc();
    final bucket =
        now.millisecondsSinceEpoch ~/ const Duration(minutes: 5).inMilliseconds;
    return {
      'sensor_id': reading.sensorId,
      'alert_type': type,
      'severity': severity,
      'status': 'active',
      'message': '$title: $message',
      'detected_at': now.toIso8601String(),
      'dedupe_key': '${reading.sensorId}:$type:$bucket',
    };
  }

  String _alertKindKey(Map<String, Object?> alert) =>
      '${alert['sensor_id']}:${alert['alert_type']}';

  Future<List<EnergyReadingHistory>> _readEnergyRows({
    required String sensorId,
    required DateTime since,
    required bool ascending,
    required int maxRows,
  }) async {
    final result = <EnergyReadingHistory>[];
    const pageSize = 500;
    while (result.length < maxRows) {
      final offset = result.length;
      final pageEnd = (offset + pageSize - 1).clamp(0, maxRows - 1);
      final rows = await _client
          .from('energy_readings')
          .select('voltage,current,power,energy,recorded_at')
          .eq('sensor_id', sensorId)
          .gte('recorded_at', since.toUtc().toIso8601String())
          .order('recorded_at', ascending: ascending)
          .range(offset, pageEnd);
      for (final row in rows) {
        final recordedAt = DateTime.tryParse(row['recorded_at'] as String);
        if (recordedAt == null) {
          throw const FormatException(
            'Energy reading contains an invalid timestamp.',
          );
        }
        result.add(
          EnergyReadingHistory(
            voltage: _parseNumber(row['voltage']),
            current: _parseNumber(row['current']),
            power: _parseNumber(row['power']),
            energy: _parseNumber(row['energy']),
            recordedAt: recordedAt.toLocal(),
          ),
        );
      }
      if (rows.length < pageSize || result.length >= maxRows) {
        break;
      }
    }
    return result;
  }

  double _counterDelta(List<EnergyReadingHistory> readings) {
    if (readings.length < 2) return 0;
    final values = readings.map((reading) => reading.energy).toList();
    final first = values.first;
    final last = values.last;
    return last >= first ? last - first : last;
  }

  double _average(List<double> values) =>
      values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;

  double _max(double first, double second) => first > second ? first : second;
  double _min(double first, double second) => first < second ? first : second;

  double _parseNumber(Object value) {
    if (value is num && value.isFinite) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && parsed.isFinite) return parsed;
    }
    throw const FormatException('Sensor status contains an invalid number.');
  }
}
