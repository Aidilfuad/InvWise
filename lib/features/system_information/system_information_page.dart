import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/constants/app_colors.dart';
import '../../services/app_update_service.dart';
import '../../services/offline_cache_service.dart';
import '../../services/profile_service.dart';
import '../../services/role_access_service.dart';
import '../../services/sensor_monitoring_service.dart';

class SystemInformationPage extends StatefulWidget {
  const SystemInformationPage({super.key});

  @override
  State<SystemInformationPage> createState() => _SystemInformationPageState();
}

class _SystemInformationPageState extends State<SystemInformationPage> {
  bool _loading = true;
  bool? _databaseConnected;
  bool? _nodeRedOnline;
  String? _nodeRedMessage;
  int _onlineSensors = 0;
  int _totalSensors = 0;
  String _role = 'Unknown';
  String _version = currentAppVersion;
  String _buildVersion = 'Unavailable';
  String _buildDate = 'Not supplied by build';
  String _latestVersion = 'Unavailable';
  String _updateStatus = 'Unavailable';
  AppUpdateStatus? _updateStatusValue;
  String? _error;

  static const String _nodeRedHealthUrl = String.fromEnvironment(
    'NODE_RED_HEALTH_URL',
  );
  final _sensorService = SensorMonitoringService();
  final _updateService = AppUpdateService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _nodeRedOnline = null;
    _nodeRedMessage = null;
    _onlineSensors = 0;
    _totalSensors = 0;
    var failedChecks = 0;
    var knownChecks = 1;
    try {
      final update = await _updateService.checkForUpdates();
      _version = update.installedVersion;
      _latestVersion = update.release?.version ?? 'Unavailable';
      _updateStatusValue = update.status;
      _updateStatus = switch (update.status) {
        AppUpdateStatus.latest => 'Up To Date',
        AppUpdateStatus.available => 'Update Available',
        AppUpdateStatus.required => 'Update Required',
        AppUpdateStatus.unavailable => 'Unavailable',
      };
    } catch (error) {
      _updateStatusValue = AppUpdateStatus.unavailable;
      _updateStatus = 'Unavailable';
      _error = 'Unable to read installed app version: $error';
    }
    try {
      _buildVersion = await AppUpdateService.buildVersion();
    } catch (error) {
      _buildVersion = 'Unavailable';
      _error = _error == null
          ? 'Unable to read build version: $error'
          : '$_error\nUnable to read build version: $error';
    }
    _buildDate = await AppUpdateService.buildDate();
    try {
      await Supabase.instance.client
          .from('app_settings')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      _databaseConnected = true;
    } catch (error) {
      _databaseConnected = false;
      failedChecks++;
      _error = 'Unable to verify database connectivity: $error';
    }
    if (_nodeRedHealthUrl.trim().isNotEmpty) {
      knownChecks++;
      try {
        final response = await http
            .get(Uri.parse(_nodeRedHealthUrl))
            .timeout(const Duration(seconds: 8));
        _nodeRedOnline =
            response.statusCode >= 200 && response.statusCode < 300;
        if (!_nodeRedOnline!) failedChecks++;
      } catch (error) {
        _nodeRedOnline = false;
        _nodeRedMessage = '$error';
        failedChecks++;
      }
    }
    try {
      final readings = await _sensorService.fetchLatest();
      _totalSensors = readings.length;
      _onlineSensors = readings
          .where(
            (reading) =>
                reading.presenceAt(DateTime.now()) == SensorPresence.online,
          )
          .length;
      knownChecks++;
      if (_totalSensors == 0 || _onlineSensors != _totalSensors) {
        failedChecks++;
      }
    } catch (error) {
      _error = _error == null
          ? 'Unable to load telemetry status: $error'
          : '$_error\n$error';
      knownChecks++;
      failedChecks++;
    }
    try {
      final profile = await ProfileService().getCurrentProfile();
      _role = profile?.role ?? 'Unknown';
    } catch (_) {
      _role = RoleAccessService.instance.role.name;
    }
    _failedChecks = failedChecks;
    _knownChecks = knownChecks;
    if (mounted) setState(() => _loading = false);
  }

  int _failedChecks = 0;
  int _knownChecks = 1;

  @override
  void dispose() {
    _updateService.dispose();
    super.dispose();
  }

  Widget _status(String label, String value, {required bool? healthy}) =>
      ListTile(
        leading: Icon(
          healthy == null
              ? Icons.help_outline
              : healthy
              ? Icons.check_circle_outline
              : Icons.error_outline,
          color: healthy == null
              ? AppColors.textSecondary
              : healthy
              ? AppColors.success
              : AppColors.danger,
        ),
        title: Text(label),
        trailing: Text(value),
      );

  @override
  Widget build(BuildContext context) {
    final health = _knownChecks == 0
        ? 0
        : ((_knownChecks - _failedChecks) / _knownChecks * 100).round();
    final lastSync = OfflineCacheService.instance.lastSyncedAt;
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Information'),
        actions: [
          IconButton(
            tooltip: 'Refresh system status',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _status('Installed Version', _version, healthy: true),
                    _status('Build Version', _buildVersion, healthy: null),
                    _status('Build Date', _buildDate, healthy: null),
                    _status(
                      'Latest Available Version',
                      _latestVersion,
                      healthy: null,
                    ),
                    _status(
                      'Update Status',
                      _updateStatus,
                      healthy: _updateStatusValue == AppUpdateStatus.latest
                          ? true
                          : _updateStatusValue == AppUpdateStatus.required
                          ? false
                          : null,
                    ),
                    _status(
                      'Supabase Connection',
                      _databaseConnected == true ? 'Connected' : 'Unavailable',
                      healthy: _databaseConnected,
                    ),
                    _status(
                      'Database Status',
                      _databaseConnected == true ? 'Available' : 'Unavailable',
                      healthy: _databaseConnected,
                    ),
                    _status(
                      'Node-RED Status',
                      _nodeRedHealthUrl.isEmpty
                          ? 'Not configured'
                          : _nodeRedOnline == true
                          ? 'Online'
                          : 'Offline',
                      healthy: _nodeRedHealthUrl.isEmpty
                          ? null
                          : _nodeRedOnline,
                    ),
                    _status(
                      'Telemetry Status',
                      _totalSensors > 0 ? 'Receiving data' : 'No sensor data',
                      healthy: _totalSensors > 0,
                    ),
                    _status(
                      'Connected Sensors',
                      '$_onlineSensors / $_totalSensors online',
                      healthy:
                          _totalSensors > 0 && _onlineSensors == _totalSensors,
                    ),
                    _status(
                      'Last Sync Time',
                      lastSync?.toLocal().toString() ?? 'Not available',
                      healthy: lastSync != null,
                    ),
                    _status('Current User Role', _role, healthy: null),
                    Card(
                      child: ListTile(
                        title: const Text('System Health'),
                        trailing: Text('$health%'),
                      ),
                    ),
                    if (_nodeRedMessage != null || _error != null)
                      Text(
                        [
                          _nodeRedMessage,
                          _error,
                        ].whereType<String>().join('\n'),
                        style: TextStyle(color: AppColors.danger),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
