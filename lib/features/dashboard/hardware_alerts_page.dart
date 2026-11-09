import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../services/reports_service.dart';
import '../../services/sensor_monitoring_service.dart';
import '../../services/telemetry_csv_export_service.dart';

class HardwareAlertsPage extends StatefulWidget {
  const HardwareAlertsPage({super.key, this.service});

  final SensorMonitoringService? service;

  @override
  State<HardwareAlertsPage> createState() => _HardwareAlertsPageState();
}

class _HardwareAlertsPageState extends State<HardwareAlertsPage> {
  late final SensorMonitoringService _service =
      widget.service ?? SensorMonitoringService();
  List<TelemetryAlert> _alerts = const [];
  bool _isLoading = true;
  bool _isExporting = false;
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
      final readings = await _service.fetchLatest();
      await _service.evaluateAlerts(readings);
      final alerts = await _service.fetchAlerts();
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load Hardware Alerts';
        _isLoading = false;
      });
      debugPrint('Hardware Alerts load failed: $error');
    }
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      final rows = _alerts
          .map(
            (alert) => [
              alert.detectedAt.toIso8601String(),
              alert.sensorName,
              alert.alertType,
              alert.severity,
              alert.status,
              alert.message,
            ],
          )
          .toList(growable: false);
      await const TelemetryCsvExportService().export(
        context: context,
        report: ReportTable(
          title: 'Hardware Alerts',
          headers: const [
            'Timestamp',
            'Sensor',
            'Alert Type',
            'Severity',
            'Status',
            'Message',
          ],
          rows: rows,
          metrics: const [],
        ),
        fileName: 'invwise_hardware_alerts.csv',
      );
    } catch (error) {
      if (mounted) _showMessage('Unable to export Hardware Alerts: $error');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Hardware Alerts'),
      actions: [
        IconButton(
          tooltip: 'Export CSV',
          onPressed: _isExporting || _alerts.isEmpty ? null : _export,
          icon: _isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
        ),
        IconButton(
          tooltip: 'Refresh alerts',
          onPressed: _isLoading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    backgroundColor: AppColors.background,
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
        ? _ErrorState(message: _errorMessage!, onRetry: _load)
        : _alerts.isEmpty
        ? const _EmptyState()
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _alerts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _AlertTile(alert: _alerts[index]),
          ),
  );
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final TelemetryAlert alert;

  @override
  Widget build(BuildContext context) {
    final severityColor = alert.severity == 'critical'
        ? AppColors.danger
        : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.message.split(':').first,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _Badge(label: alert.severity.toUpperCase(), color: severityColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${alert.sensorName} · ${alert.status}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            alert.detectedAt.toLocal().toString(),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            alert.message,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withAlpha(24),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 44, color: AppColors.success),
        const SizedBox(height: 10),
        const Text('No Active Hardware Alerts'),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
