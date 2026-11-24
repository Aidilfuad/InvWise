import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../services/sensor_monitoring_service.dart';
import 'hardware_alerts_page.dart';
import 'telemetry_analytics_page.dart';
import 'telemetry_history_page.dart';
import 'telemetry_settings_page.dart';

class TelemetryDetailsPage extends StatelessWidget {
  const TelemetryDetailsPage({
    super.key,
    required this.readings,
    this.service,
    this.clock,
  });

  final List<SensorReading> readings;
  final SensorMonitoringService? service;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final energyMeter = _firstOfType('energy_meter');
    final toggleSwitch = _firstOfType('toggle_switch');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry Details'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Telemetry options',
            onSelected: (value) {
              final Widget? page = switch (value) {
                'settings' => TelemetrySettingsPage(service: service),
                'alerts' => HardwareAlertsPage(service: service),
                _ => null,
              };
              if (page != null) {
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => page));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'settings',
                child: Text('Telemetry Settings'),
              ),
              PopupMenuItem(value: 'alerts', child: Text('Hardware Alerts')),
            ],
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (energyMeter != null)
            _detailsCard(
              context,
              title: 'DDS669',
              icon: Icons.bolt_rounded,
              reading: energyMeter,
              rows: [
                ('Voltage', _value(energyMeter.voltage, 'V')),
                ('Current', _value(energyMeter.current, 'A')),
                ('Power', _value(energyMeter.power, 'W')),
                ('Energy', _value(energyMeter.energy, 'kWh')),
                ('Status', _presenceLabel(energyMeter)),
                ('Last Seen', _lastSeen(energyMeter.lastSeen)),
              ],
            ),
          if (energyMeter != null && toggleSwitch != null)
            const SizedBox(height: 12),
          if (toggleSwitch != null)
            _detailsCard(
              context,
              title: 'Toggle Switch',
              icon: Icons.toggle_on_rounded,
              reading: toggleSwitch,
              rows: [
                ('State', _switchState(toggleSwitch)),
                ('Status', _presenceLabel(toggleSwitch)),
                ('Last Seen', _lastSeen(toggleSwitch.lastSeen)),
              ],
            ),
          if (energyMeter != null || toggleSwitch != null) ...[
            const SizedBox(height: 12),
            if (energyMeter != null)
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TelemetryAnalyticsPage(
                      sensorId: energyMeter.sensorId,
                      service: service,
                    ),
                  ),
                ),
                icon: const Icon(Icons.insights_outlined),
                label: const Text('Telemetry Analytics'),
              ),
            if (energyMeter != null) const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TelemetryHistoryPage(
                    energySensorId: energyMeter?.sensorId,
                    switchSensorId: toggleSwitch?.sensorId,
                    service: service,
                  ),
                ),
              ),
              icon: const Icon(Icons.history_rounded),
              label: const Text('View Telemetry History'),
            ),
          ],
          if (energyMeter == null && toggleSwitch == null)
            const _EmptyDetails(),
        ],
      ),
    );
  }

  SensorReading? _firstOfType(String type) {
    for (final reading in readings) {
      if (reading.sensorType == type) return reading;
    }
    return null;
  }

  Widget _detailsCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required SensorReading reading,
    required List<(String, String)> rows,
  }) {
    final presence = reading.presenceAt(clock?.call() ?? DateTime.now());
    final statusColor = _statusColor(presence);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusChip(label: _presenceLabel(reading), color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _presenceLabel(SensorReading reading) =>
      switch (reading.presenceAt(clock?.call() ?? DateTime.now())) {
        SensorPresence.online => 'Online',
        SensorPresence.warning => 'Warning',
        SensorPresence.offline => 'Offline',
      };

  Color _statusColor(SensorPresence presence) => switch (presence) {
    SensorPresence.online => AppColors.success,
    SensorPresence.warning => AppColors.warning,
    SensorPresence.offline => AppColors.danger,
  };

  String _switchState(SensorReading reading) {
    final state = reading.valueText?.trim().toUpperCase();
    return state == 'ON' || (state != 'OFF' && (reading.valueNumeric ?? 0) != 0)
        ? 'ON'
        : 'OFF';
  }

  String _value(double? value, String unit) =>
      value == null ? '--' : '${_formatNumber(value)}$unit';

  String _formatNumber(double value) {
    if (value == value.truncateToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }

  String _lastSeen(DateTime? dateTime) {
    if (dateTime == null) return 'Unavailable';
    final local = dateTime.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '$hour:${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')} '
        '${local.hour < 12 ? 'AM' : 'PM'}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withAlpha(24),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _EmptyDetails extends StatelessWidget {
  const _EmptyDetails();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      'No sensor data available',
      style: TextStyle(color: AppColors.textSecondary),
    ),
  );
}
