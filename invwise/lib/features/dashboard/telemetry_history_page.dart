import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../services/reports_service.dart';
import '../../services/sensor_monitoring_service.dart';
import '../../services/telemetry_csv_export_service.dart';
import '../../widgets/searchable_dropdown_form_field.dart';

class TelemetryHistoryPage extends StatefulWidget {
  const TelemetryHistoryPage({
    super.key,
    this.energySensorId,
    this.switchSensorId,
    this.service,
  });

  final String? energySensorId;
  final String? switchSensorId;
  final SensorMonitoringService? service;

  @override
  State<TelemetryHistoryPage> createState() => _TelemetryHistoryPageState();
}

class _TelemetryHistoryPageState extends State<TelemetryHistoryPage> {
  late final SensorMonitoringService _service =
      widget.service ?? SensorMonitoringService();
  List<EnergyReadingHistory> _energyReadings = const [];
  List<SwitchEventHistory> _switchEvents = const [];
  List<EnergyReadingHistory> _chartReadings = const [];
  SensorReading? _latestSensorReading;
  TelemetryPeriod _period = TelemetryPeriod.last24Hours;
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadHistory());
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final energyFuture = widget.energySensorId == null
          ? Future<List<EnergyReadingHistory>>.value(const [])
          : _service.fetchEnergyHistory(widget.energySensorId!);
      final chartFuture = widget.energySensorId == null
          ? Future<List<EnergyReadingHistory>>.value(const [])
          : _service.fetchEnergyChart(widget.energySensorId!, _period);
      final switchFuture = widget.switchSensorId == null
          ? Future<List<SwitchEventHistory>>.value(const [])
          : _service.fetchSwitchHistory(widget.switchSensorId!);
      final sensorId = widget.energySensorId ?? widget.switchSensorId;
      final latestFuture = sensorId == null
          ? Future<List<SensorReading>>.value(const [])
          : _service.fetchLatest();
      final results = await Future.wait<Object>([
        energyFuture,
        switchFuture,
        chartFuture,
        latestFuture,
      ]);
      if (!mounted) return;
      setState(() {
        _energyReadings = results[0] as List<EnergyReadingHistory>;
        _switchEvents = results[1] as List<SwitchEventHistory>;
        _chartReadings = results[2] as List<EnergyReadingHistory>;
        _latestSensorReading = (results[3] as List<SensorReading>)
            .where((reading) => reading.sensorId == sensorId)
            .firstOrNull;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load telemetry data';
        _isLoading = false;
      });
      debugPrint('Telemetry history load failed: $error');
    }
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      if (widget.energySensorId != null) {
        final readings = await _service.fetchEnergyExport(
          widget.energySensorId!,
        );
        if (!mounted) return;
        await const TelemetryCsvExportService().export(
          context: context,
          report: ReportTable(
            title: 'Energy Readings',
            headers: const [
              'Recorded At',
              'Voltage (V)',
              'Current (A)',
              'Power (W)',
              'Energy (kWh)',
            ],
            rows: readings
                .map(
                  (reading) => [
                    reading.recordedAt.toIso8601String(),
                    '${reading.voltage}',
                    '${reading.current}',
                    '${reading.power}',
                    '${reading.energy}',
                  ],
                )
                .toList(growable: false),
            metrics: const [],
          ),
          fileName: 'invwise_energy_readings.csv',
        );
        if (!mounted) return;
      }
      if (widget.switchSensorId != null) {
        final events = await _service.fetchSwitchExport(widget.switchSensorId!);
        if (!mounted) return;
        await const TelemetryCsvExportService().export(
          context: context,
          report: ReportTable(
            title: 'Switch Events',
            headers: const ['Recorded At', 'State'],
            rows: events
                .map(
                  (event) => [event.recordedAt.toIso8601String(), event.state],
                )
                .toList(growable: false),
            metrics: const [],
          ),
          fileName: 'invwise_switch_events.csv',
        );
        if (!mounted) return;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Unable to export CSV: $error')),
          );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Telemetry History'),
      actions: [
        IconButton(
          tooltip: 'Export CSV',
          onPressed: _isExporting || _isLoading ? null : _export,
          icon: _isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
        ),
      ],
    ),
    backgroundColor: AppColors.background,
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
        ? _ErrorState(message: _errorMessage!, onRetry: _loadHistory)
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.energySensorId != null) ...[
                    const _HistoryHeading('DDS669 · Latest 20 readings'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(child: Text('Trend period')),
                        SizedBox(
                          width: 220,
                          child: SearchableDropdownFormField(
                            initialValue: _period.name,
                            decoration: const InputDecoration(
                              labelText: 'Trend period',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            options: TelemetryPeriod.values
                                .map((period) => period.name)
                                .toList(),
                            optionLabels: {
                              for (final period in TelemetryPeriod.values)
                                period.name: period.label,
                            },
                            enabled: !_isLoading,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(
                                () => _period = TelemetryPeriod.values
                                    .firstWhere(
                                      (period) => period.name == value,
                                    ),
                              );
                              unawaited(_loadHistory());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final (label, value, latestValue, unit) in [
                      (
                        'Voltage Trend',
                        _chartReadings
                            .map((reading) => reading.voltage)
                            .toList(),
                        _latestSensorReading?.voltage,
                        'V',
                      ),
                      (
                        'Current Trend',
                        _chartReadings
                            .map((reading) => reading.current)
                            .toList(),
                        _latestSensorReading?.current,
                        'A',
                      ),
                      (
                        'Power Trend',
                        _chartReadings.map((reading) => reading.power).toList(),
                        _latestSensorReading?.power,
                        'W',
                      ),
                      (
                        'Energy Trend',
                        _chartReadings
                            .map((reading) => reading.energy)
                            .toList(),
                        _latestSensorReading?.energy,
                        'kWh',
                      ),
                    ]) ...[
                      _TrendChart(
                        title: label,
                        values: value,
                        latestValue: latestValue,
                        latestReading: _latestSensorReading,
                        unit: unit,
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                    if (_energyReadings.isEmpty)
                      _LastReadingCard(reading: _latestSensorReading)
                    else
                      for (final reading in _energyReadings)
                        _EnergyHistoryTile(reading: reading),
                  ],
                  if (widget.energySensorId != null &&
                      widget.switchSensorId != null)
                    const SizedBox(height: 20),
                  if (widget.switchSensorId != null) ...[
                    const _HistoryHeading('Switch · Latest 20 events'),
                    const SizedBox(height: 8),
                    if (_switchEvents.isEmpty)
                      const _EmptyHistory()
                    else
                      for (final event in _switchEvents)
                        _SwitchHistoryTile(event: event),
                  ],
                ],
              ),
            ),
          ),
  );
}

class _HistoryHeading extends StatelessWidget {
  const _HistoryHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.title,
    required this.values,
    required this.latestValue,
    required this.latestReading,
    required this.unit,
  });

  final String title;
  final List<double> values;
  final double? latestValue;
  final SensorReading? latestReading;
  final String unit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          width: double.infinity,
          child: values.isEmpty
              ? latestValue != null && latestReading != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Most recent: ${_format(latestValue!)} $unit',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${latestReading!.sensorName} · ${latestReading!.warehouseName ?? 'Warehouse unavailable'}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          latestReading!.updatedLabelAt(DateTime.now()),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Text(
                        'No readings in this period',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
              : CustomPaint(
                  painter: _TelemetryChartPainter(
                    values: values,
                    color: AppColors.primary,
                    gridColor: AppColors.border,
                  ),
                  child: const SizedBox.expand(),
                ),
        ),
      ],
    ),
  );
}

class _LastReadingCard extends StatelessWidget {
  const _LastReadingCard({required this.reading});

  final SensorReading? reading;

  @override
  Widget build(BuildContext context) {
    final sensor = reading;
    if (sensor == null) return const _EmptyHistory();
    final value = sensor.valueNumeric == null
        ? sensor.valueText ?? 'Reading unavailable'
        : '${_format(sensor.valueNumeric!)} ${_unitFor(sensor.sensorType)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most recent sensor reading',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${sensor.sensorName} · ${sensor.sensorCode} · ${sensor.warehouseName ?? 'Warehouse unavailable'}',
            ),
            Text(
              sensor.lastSeen == null
                  ? 'Timestamp unavailable'
                  : _dateTime(sensor.lastSeen!),
            ),
          ],
        ),
      ),
    );
  }

  String _unitFor(String sensorType) {
    final type = sensorType.toLowerCase();
    if (type.contains('temperature') || type.contains('temp')) return '°C';
    if (type.contains('humidity')) return '%';
    if (type.contains('voltage')) return 'V';
    if (type.contains('current')) return 'A';
    if (type.contains('power')) return 'W';
    if (type.contains('energy')) return 'kWh';
    return '';
  }
}

class _TelemetryChartPainter extends CustomPainter {
  const _TelemetryChartPainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.7;
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (values.isEmpty) return;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final normalized = range == 0 ? 0.5 : (values[index] - minValue) / range;
      final y = size.height - (normalized * (size.height - 12)) - 6;
      points.add(Offset(x, y));
    }
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (points.length == 1) {
      canvas.drawCircle(points.first, 3, linePaint..style = PaintingStyle.fill);
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TelemetryChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor;
}

class _EnergyHistoryTile extends StatelessWidget {
  const _EnergyHistoryTile({required this.reading});

  final EnergyReadingHistory reading;

  @override
  Widget build(BuildContext context) => _HistoryTile(
    dateTime: reading.recordedAt,
    child: Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _metric('Voltage', '${_format(reading.voltage)}V'),
        _metric('Current', '${_format(reading.current)}A'),
        _metric('Power', '${_format(reading.power)}W'),
        _metric('Energy', '${_format(reading.energy)}kWh'),
      ],
    ),
  );
}

class _SwitchHistoryTile extends StatelessWidget {
  const _SwitchHistoryTile({required this.event});

  final SwitchEventHistory event;

  @override
  Widget build(BuildContext context) => _HistoryTile(
    dateTime: event.recordedAt,
    child: Text(
      event.state.toUpperCase(),
      style: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.dateTime, required this.child});

  final DateTime dateTime;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _dateTime(dateTime),
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      'No telemetry history available',
      style: TextStyle(color: AppColors.textSecondary),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

Widget _metric(String label, String value) => Text(
  '$label: $value',
  style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
);

String _format(double value) => value == value.truncateToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

String _dateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '$hour:${local.minute.toString().padLeft(2, '0')}:'
      '${local.second.toString().padLeft(2, '0')} '
      '${local.hour < 12 ? 'AM' : 'PM'}';
}
