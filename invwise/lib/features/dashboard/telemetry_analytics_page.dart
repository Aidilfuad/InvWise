import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../services/sensor_monitoring_service.dart';
import 'telemetry_energy_reports_page.dart';
import 'telemetry_settings_page.dart';

class TelemetryAnalyticsPage extends StatefulWidget {
  const TelemetryAnalyticsPage({
    super.key,
    required this.sensorId,
    this.service,
  });

  final String sensorId;
  final SensorMonitoringService? service;

  @override
  State<TelemetryAnalyticsPage> createState() => _TelemetryAnalyticsPageState();
}

class _TelemetryAnalyticsPageState extends State<TelemetryAnalyticsPage> {
  late final SensorMonitoringService _service =
      widget.service ?? SensorMonitoringService();
  TelemetryAnalytics? _analytics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final analytics = await _service.fetchAnalytics(widget.sensorId);
      if (!mounted) return;
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load telemetry analytics';
        _isLoading = false;
      });
      debugPrint('Telemetry analytics load failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Telemetry Analytics'),
      actions: [
        IconButton(
          tooltip: 'Telemetry settings',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TelemetrySettingsPage(service: _service),
            ),
          ),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
    backgroundColor: AppColors.background,
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_errorMessage!),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MetricsGrid(analytics: _analytics!),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TelemetryEnergyReportsPage(
                      sensorId: widget.sensorId,
                      service: _service,
                    ),
                  ),
                ),
                icon: const Icon(Icons.summarize_outlined),
                label: const Text('Energy Reports'),
              ),
            ],
          ),
  );
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.analytics});

  final TelemetryAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Current Power', _value(analytics.currentPower, 'W'), Icons.bolt),
      (
        'Current Energy',
        _value(analytics.currentEnergy, 'kWh'),
        Icons.energy_savings_leaf,
      ),
      (
        'Daily Average Power',
        _value(analytics.dailyAveragePower, 'W'),
        Icons.show_chart,
      ),
      (
        'Peak Power Today',
        _value(analytics.peakPowerToday, 'W'),
        Icons.trending_up,
      ),
      (
        'Lowest Power Today',
        _value(analytics.lowestPowerToday, 'W'),
        Icons.trending_down,
      ),
      (
        'Energy Consumed Today',
        _value(analytics.energyConsumedToday, 'kWh'),
        Icons.today,
      ),
      (
        'Estimated Monthly Consumption',
        _value(analytics.estimatedMonthlyConsumption, 'kWh'),
        Icons.calendar_month,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 2;
        final itemWidth = (constraints.maxWidth - 10 * (columns - 1)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (label, value, icon) in metrics)
              SizedBox(
                width: itemWidth,
                child: _MetricCard(label: label, value: value, icon: icon),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 112),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

String _value(double value, String unit) {
  final formatted = value == value.truncateToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  return '$formatted $unit';
}
