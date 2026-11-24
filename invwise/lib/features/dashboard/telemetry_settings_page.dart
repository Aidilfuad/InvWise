import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../services/sensor_monitoring_service.dart';

class TelemetrySettingsPage extends StatefulWidget {
  const TelemetrySettingsPage({super.key, this.service});

  final SensorMonitoringService? service;

  @override
  State<TelemetrySettingsPage> createState() => _TelemetrySettingsPageState();
}

class _TelemetrySettingsPageState extends State<TelemetrySettingsPage> {
  late final SensorMonitoringService _service =
      widget.service ?? SensorMonitoringService();
  final _formKey = GlobalKey<FormState>();
  final _voltageController = TextEditingController();
  final _currentController = TextEditingController();
  final _offlineController = TextEditingController();
  bool _realtimeEnabled = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _voltageController.dispose();
    _currentController.dispose();
    _offlineController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final settings = await _service.fetchSettings();
      if (!mounted) return;
      setState(() {
        _voltageController.text = settings.voltageWarningThreshold.toString();
        _currentController.text = settings.currentWarningThreshold.toString();
        _offlineController.text = settings.offlineTimeoutMinutes.toString();
        _realtimeEnabled = settings.realtimeEnabled;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load telemetry settings';
        _isLoading = false;
      });
      debugPrint('Telemetry settings load failed: $error');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _service.saveSettings(
        TelemetrySettings(
          voltageWarningThreshold: double.parse(_voltageController.text),
          currentWarningThreshold: double.parse(_currentController.text),
          offlineTimeoutMinutes: int.parse(_offlineController.text),
          realtimeEnabled: _realtimeEnabled,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Telemetry settings saved')),
        );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to save telemetry settings');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Unable to save telemetry settings: $error')),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Telemetry Settings')),
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
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _numberField(
                  controller: _voltageController,
                  label: 'Voltage Warning Threshold (V)',
                  decimal: true,
                ),
                const SizedBox(height: 12),
                _numberField(
                  controller: _currentController,
                  label: 'Current Warning Threshold (A)',
                  decimal: true,
                ),
                const SizedBox(height: 12),
                _numberField(
                  controller: _offlineController,
                  label: 'Offline Timeout (minutes)',
                  decimal: false,
                  min: 2,
                  max: 60,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _realtimeEnabled,
                  onChanged: (value) =>
                      setState(() => _realtimeEnabled = value),
                  title: const Text('Realtime Enabled'),
                  subtitle: const Text(
                    'Refresh dashboard telemetry when sensor status changes.',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Settings'),
                ),
              ],
            ),
          ),
  );

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required bool decimal,
    double min = 0.000001,
    double max = double.infinity,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final parsed = double.tryParse(value ?? '');
      if (parsed == null || !parsed.isFinite) return 'Enter a valid number';
      if (parsed < min || parsed > max) {
        return 'Value must be between $min and $max';
      }
      if (!decimal && parsed != parsed.truncateToDouble()) {
        return 'Enter a whole number';
      }
      return null;
    },
  );
}
