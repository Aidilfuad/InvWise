import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/constants/app_colors.dart';
import '../../../services/sensor_monitoring_service.dart';
import '../telemetry_details_page.dart';

class SensorMonitoringCard extends StatefulWidget {
  const SensorMonitoringCard({
    super.key,
    this.service,
    this.clock,
    this.offlineCheckInterval = const Duration(minutes: 1),
  });

  final SensorMonitoringService? service;
  final DateTime Function()? clock;
  final Duration? offlineCheckInterval;

  @override
  State<SensorMonitoringCard> createState() => _SensorMonitoringCardState();
}

class _SensorMonitoringCardState extends State<SensorMonitoringCard> {
  late final SensorMonitoringService _service =
      widget.service ?? SensorMonitoringService();
  List<SensorReading> _readings = const [];
  DateTime? _lastSync;
  bool _isSyncing = false;
  bool _hasLoadError = false;
  int _offlineTimeoutMinutes = 5;
  Timer? _ageTimer;
  Timer? _offlineCheckTimer;
  RealtimeChannel? _sensorStatusChannel;

  @override
  void initState() {
    super.initState();
    _ageTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _readings.isNotEmpty) setState(() {});
    });
    final offlineCheckInterval = widget.offlineCheckInterval;
    if (offlineCheckInterval != null) {
      _offlineCheckTimer = Timer.periodic(offlineCheckInterval, (_) {
        if (mounted && !_isSyncing) unawaited(_sync(showFeedback: false));
      });
    }
    unawaited(_loadRealtimeSettings());
    unawaited(_sync(showFeedback: false));
  }

  @override
  void dispose() {
    _ageTimer?.cancel();
    _offlineCheckTimer?.cancel();
    final channel = _sensorStatusChannel;
    if (channel != null) unawaited(_service.removeChannel(channel));
    super.dispose();
  }

  Future<void> _loadRealtimeSettings() async {
    try {
      final settings = await _service.fetchSettings();
      if (!mounted) return;
      setState(() => _offlineTimeoutMinutes = settings.offlineTimeoutMinutes);
      if (settings.realtimeEnabled && _sensorStatusChannel == null) {
        _sensorStatusChannel = _service.subscribeToSensorStatus(() {
          unawaited(_sync(showFeedback: false));
        });
      } else if (!settings.realtimeEnabled) {
        final channel = _sensorStatusChannel;
        if (channel != null) {
          await _service.removeChannel(channel);
          _sensorStatusChannel = null;
        }
      }
    } catch (error) {
      debugPrint('Telemetry realtime settings unavailable: $error');
    }
  }

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  Future<void> _sync({required bool showFeedback}) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final readings = (await _service.fetchLatest())
          .where(_isConfiguredSensor)
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _readings = readings;
        _lastSync = _now();
        _hasLoadError = false;
      });
      unawaited(_evaluateAlerts(readings));
      if (showFeedback) {
        unawaited(
          _service.recordSyncActivity(
            succeeded: true,
            sensorCount: readings.length,
          ),
        );
      }
      if (showFeedback) _showMessage('Sensor data synced successfully');
    } catch (error) {
      if (!mounted) return;
      setState(() => _hasLoadError = true);
      if (showFeedback) {
        unawaited(_service.recordSyncActivity(succeeded: false));
      }
      if (showFeedback) _showMessage('Unable to sync sensor data');
      debugPrint('Sensor monitoring sync failed: $error');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _evaluateAlerts(List<SensorReading> readings) async {
    try {
      await _service.evaluateAlerts(readings);
    } catch (error) {
      debugPrint('Telemetry alert evaluation failed: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openDetails() async {
    final configuredReadings = _readings.where(_isConfiguredSensor).toList();
    if (configuredReadings.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelemetryDetailsPage(
          readings: configuredReadings,
          service: _service,
          clock: widget.clock,
        ),
      ),
    );
    if (mounted) {
      await _loadRealtimeSettings();
      await _sync(showFeedback: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleReadings = _readings
        .where(_isConfiguredSensor)
        .toList(growable: false);
    final counts = _presenceCounts(visibleReadings);
    final sensorCards = visibleReadings
        .map(_configuredSensorSummary)
        .toList(growable: false);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: visibleReadings.isEmpty ? null : _openDetails,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sensor Monitoring',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Manual Sync',
                    onPressed: _isSyncing
                        ? null
                        : () => _sync(showFeedback: true),
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.primary,
                    ),
                    icon: _isSyncing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${visibleReadings.length} Sensors',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (visibleReadings.isNotEmpty)
                    _summaryStatus(
                      '${counts[SensorPresence.online] ?? 0} Online',
                      AppColors.success,
                    ),
                  if ((counts[SensorPresence.warning] ?? 0) > 0)
                    _summaryStatus(
                      '${counts[SensorPresence.warning]} Warning',
                      AppColors.warning,
                    ),
                  if ((counts[SensorPresence.offline] ?? 0) > 0)
                    _summaryStatus(
                      '${counts[SensorPresence.offline]} Offline',
                      AppColors.danger,
                    ),
                  if (visibleReadings.isNotEmpty)
                    _summaryStatus(
                      '${_healthPercent(counts, visibleReadings.length)}% Health',
                      _healthPercent(counts, visibleReadings.length) >= 80
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Last Sync: ${_lastSync == null ? '--:--:--' : _formatTime(_lastSync!)}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 9),
              if (_hasLoadError && visibleReadings.isEmpty)
                _loadErrorState()
              else if (visibleReadings.isEmpty)
                Text(
                  'No configured sensor data available',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                )
              else ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 600) {
                      const columns = 2;
                      const gap = 8.0;
                      final cardWidth =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final card in sensorCards)
                            SizedBox(width: cardWidth, child: card),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        for (
                          var index = 0;
                          index < sensorCards.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(height: 7),
                          sensorCards[index],
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _openDetails,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('View Details →'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadErrorState() => Row(
    children: [
      Expanded(
        child: Text(
          'Unable to load telemetry data',
          style: TextStyle(fontSize: 12, color: AppColors.danger),
        ),
      ),
      TextButton(
        onPressed: _isSyncing ? null : () => _sync(showFeedback: false),
        child: const Text('Retry'),
      ),
    ],
  );

  Widget _energySummary(SensorReading reading) {
    final voltage = reading.voltage;
    final current = reading.current;
    final power = reading.power;
    final energy = reading.energy;
    return _sensorSummary(
      icon: Icons.bolt_rounded,
      title: _energyName(reading),
      reading: reading,
      body: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _highlightMetric('Voltage', _valueWithUnit(voltage, 'V')),
          _highlightMetric('Current', _valueWithUnit(current, 'A')),
          _highlightMetric('Power', _valueWithUnit(power, 'W')),
          _highlightMetric('Energy', _valueWithUnit(energy, 'kWh')),
        ],
      ),
    );
  }

  Widget _configuredSensorSummary(SensorReading reading) {
    if (reading.sensorCode.toUpperCase().startsWith('DDS669')) {
      return _energySummary(reading);
    }
    return _switchSummary(reading);
  }

  Widget _switchSummary(SensorReading reading) => _sensorSummary(
    icon: Icons.toggle_on_rounded,
    title: 'Toggle Switch',
    reading: reading,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _switchState(reading),
          style: TextStyle(
            color: _switchState(reading) == 'ON'
                ? AppColors.success
                : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Last updated ${reading.updatedLabelAt(_now()).replaceFirst('Updated ', '')}',
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    ),
  );

  Widget _sensorSummary({
    required IconData icon,
    required String title,
    required SensorReading reading,
    required Widget body,
  }) {
    final presence = reading.presenceAt(
      _now(),
      offlineTimeoutMinutes: _offlineTimeoutMinutes,
    );
    final statusColor = _statusColor(presence);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                _presenceLabel(presence),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 2),
            child: Text(
              reading.updatedLabelAt(_now()),
              style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.only(left: 22), child: body),
        ],
      ),
    );
  }

  Widget _highlightMetric(String label, String value) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    ],
  );

  Widget _summaryStatus(String text, Color color) => Padding(
    padding: const EdgeInsets.only(left: 10),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
    ),
  );

  Map<SensorPresence, int> _presenceCounts(Iterable<SensorReading> readings) {
    final counts = <SensorPresence, int>{};
    for (final reading in readings) {
      final presence = reading.presenceAt(
        _now(),
        offlineTimeoutMinutes: _offlineTimeoutMinutes,
      );
      counts.update(presence, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  bool _isConfiguredSensor(SensorReading reading) {
    final code = reading.sensorCode.toUpperCase();
    return code.startsWith('DDS669') || code == 'SW_01';
  }

  int _healthPercent(Map<SensorPresence, int> counts, int sensorCount) {
    if (sensorCount == 0) return 0;
    final healthy = counts[SensorPresence.online] ?? 0;
    return (healthy * 100 / sensorCount).round();
  }

  String _energyName(SensorReading reading) =>
      reading.sensorCode.toUpperCase().startsWith('DDS669')
      ? 'DDS669'
      : reading.sensorName;

  String _valueWithUnit(double? value, String unit) =>
      value == null ? '--' : '${_formatNumber(value)}$unit';

  String _formatNumber(double value) {
    if (value == value.truncateToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }

  String _switchState(SensorReading reading) {
    final state = reading.valueText?.trim().toUpperCase();
    return state == 'ON' || (state != 'OFF' && (reading.valueNumeric ?? 0) != 0)
        ? 'ON'
        : 'OFF';
  }

  String _presenceLabel(SensorPresence presence) => switch (presence) {
    SensorPresence.online => 'Online',
    SensorPresence.warning => 'Warning',
    SensorPresence.offline => 'Offline',
  };

  Color _statusColor(SensorPresence presence) => switch (presence) {
    SensorPresence.online => AppColors.success,
    SensorPresence.warning => AppColors.warning,
    SensorPresence.offline => AppColors.danger,
  };

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '$hour:${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')} '
        '${local.hour < 12 ? 'AM' : 'PM'}';
  }

}
