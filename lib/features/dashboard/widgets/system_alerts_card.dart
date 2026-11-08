import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../services/sensor_monitoring_service.dart';
import '../telemetry_alerts_page.dart';

class SystemAlertsCard extends StatefulWidget {
  const SystemAlertsCard({super.key, this.service, this.compact = false});

  final SensorMonitoringService? service;
  final bool compact;

  @override
  State<SystemAlertsCard> createState() => _SystemAlertsCardState();
}

class _SystemAlertsCardState extends State<SystemAlertsCard> {
  late final SensorMonitoringService _service =
      widget.service ?? SensorMonitoringService();
  int _activeCount = 0;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) unawaited(_load());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final alerts = await _service.fetchAlerts(activeOnly: true);
      if (!mounted) return;
      setState(() {
        _activeCount = alerts.length;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load alerts';
        _isLoading = false;
      });
      debugPrint('System alert summary load failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _activeCount > 0 ? AppColors.warning : AppColors.success;
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TelemetryAlertsPage(service: _service),
          ),
        );
        if (mounted) await _load();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 10 : 14,
          vertical: widget.compact ? 7 : 11,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: color, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'System Alerts',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              _isLoading
                  ? 'Loading…'
                  : _errorMessage ??
                        (_activeCount == 0
                            ? 'No Active Alerts'
                            : '$_activeCount Active Alerts'),
              style: TextStyle(
                color: _errorMessage == null ? color : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
