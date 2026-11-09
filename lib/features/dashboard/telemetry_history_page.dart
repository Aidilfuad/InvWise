import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../services/reports_service.dart';
import '../../services/sensor_monitoring_service.dart';
import '../../services/telemetry_csv_export_service.dart';

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
      final results = await Future.wait<Object>([
        energyFuture,
        switchFuture,
        chartFuture,
      ]);
      if (!mounted) return;
      setState(() {
        _energyReadings = results[0] as List<EnergyReadingHistory>;
        _switchEvents = results[1] as List<SwitchEventHistory>;
        _chartReadings = results[2] as List<EnergyReadingHistory>;
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
                        DropdownButton<TelemetryPeriod>(
                          value: _period,
                          items: [
                            for (final period in TelemetryPeriod.values)
                              DropdownMenuItem(
                                value: period,
                                child: Text(period.label),
                              ),
                          ],
                          onChanged: _isLoading
                              ? null
                              : (period) {
                                  if (period == null) return;
                                  setState(() => _period = period);
                                  unawaited(_loadHistory());
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final (label, value) in [
                      (
                        'Voltage Trend',
                        _chartReadings
                            .map((reading) => reading.voltage)
                            .toList(),
                      ),
                      (
                        'Current Trend',
                        _chartReadings
                            .map((reading) => reading.current)
                            .toList(),
                      ),
                      (
                        'Power Trend',
                        _chartReadings.map((reading) => reading.power).toList(),
                      ),
                      (
                        'Energy Trend',
                        _chartReadings
                            .map((reading) => reading.energy)
                            .toList(),
                      ),
                    ]) ...[
                      _TrendChart(title: label, values: value),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                    if (_energyReadings.isEmpty)
                      const _EmptyHistory()
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
  const _TrendChart({required this.title, required this.values});

  final String title;
  final List<double> values;

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
              ? Center(
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
