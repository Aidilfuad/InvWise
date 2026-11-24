import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../services/sensor_monitoring_service.dart';

class TelemetryEnergyReportsPage extends StatefulWidget {
  const TelemetryEnergyReportsPage({
    super.key,
    required this.sensorId,
    this.service,
  });

  final String sensorId;
  final SensorMonitoringService? service;

  @override
  State<TelemetryEnergyReportsPage> createState() =>
      _TelemetryEnergyReportsPageState();
}

class _TelemetryEnergyReportsPageState
    extends State<TelemetryEnergyReportsPage> {
  late final SensorMonitoringService _service =
      widget.service ?? SensorMonitoringService();
  TelemetryEnergyReport? _report;
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
      final report = await _service.fetchEnergyReport(widget.sensorId);
      if (!mounted) return;
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load energy report';
        _isLoading = false;
      });
      debugPrint('Telemetry energy report failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Energy Reports')),
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
              _ReportCard(
                label: "Today's Usage",
                value: '${_format(_report!.todayUsage)} kWh',
              ),
              _ReportCard(
                label: 'This Week',
                value: '${_format(_report!.weekUsage)} kWh',
              ),
              _ReportCard(
                label: 'This Month',
                value: '${_format(_report!.monthUsage)} kWh',
              ),
              _ReportCard(
                label: 'Peak Power',
                value: '${_format(_report!.peakPower)} W',
              ),
              _ReportCard(
                label: 'Highest Current',
                value: '${_format(_report!.highestCurrent)} A',
              ),
              _ReportCard(
                label: 'Lowest Voltage',
                value: '${_format(_report!.lowestVoltage)} V',
              ),
            ],
          ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: AppColors.textSecondary)),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

String _format(double value) => value == value.truncateToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
