import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../services/app_update_service.dart';

class AppVersionPage extends StatefulWidget {
  const AppVersionPage({super.key, this.service});

  final AppUpdateService? service;

  @override
  State<AppVersionPage> createState() => _AppVersionPageState();
}

class _AppVersionPageState extends State<AppVersionPage> {
  late final AppUpdateService _service = widget.service ?? AppUpdateService();
  late final bool _ownsService = widget.service == null;
  AppUpdateCheckResult? _result;
  List<AppVersionRelease> _history = const [];
  bool _isLoading = true;
  bool _isDiagnosing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        _service.checkForUpdates(),
        _service.releaseHistory(),
      ]);
      if (mounted) {
        setState(() {
          _result = values[0] as AppUpdateCheckResult;
          _history = values[1] as List<AppVersionRelease>;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Unable to check for updates: $error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _update() async {
    final release = _result?.release;
    if (release == null) return;
    try {
      await _service.launchUpdate(release);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open update: $error')));
    }
  }

  Future<void> _validateUrl() async {
    final release = _result?.release;
    if (release == null) return;
    setState(() => _isDiagnosing = true);
    final result = await _service.validateAndOpenUpdateUrl(release);
    if (!mounted) return;
    setState(() => _isDiagnosing = false);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.passed ? 'PASS' : 'FAIL'),
        content: Text(result.reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppUpdateStatus status) => switch (status) {
    AppUpdateStatus.latest => 'Up To Date',
    AppUpdateStatus.available => 'Update Available',
    AppUpdateStatus.required => 'Update Required',
    AppUpdateStatus.unavailable => 'Unavailable',
  };

  IconData _statusIcon(AppUpdateStatus status) => switch (status) {
    AppUpdateStatus.latest => Icons.check_circle_outline,
    AppUpdateStatus.available => Icons.system_update_alt,
    AppUpdateStatus.required => Icons.warning_amber_rounded,
    AppUpdateStatus.unavailable => Icons.help_outline,
  };

  Color _statusColor(AppUpdateStatus status) => switch (status) {
    AppUpdateStatus.latest => AppColors.success,
    AppUpdateStatus.available => AppColors.primary,
    AppUpdateStatus.required => AppColors.danger,
    AppUpdateStatus.unavailable => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final release = result?.release;
    final hasUpdate =
        result?.status == AppUpdateStatus.available ||
        result?.status == AppUpdateStatus.required;

    return Scaffold(
      appBar: AppBar(title: const Text('Version Information')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: _isLoading && result == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _VersionRow(
                      label: 'Installed Version',
                      value: result?.installedVersion ?? 'Unavailable',
                    ),
                    _VersionRow(
                      label: 'Latest Version',
                      value: _isLoading
                          ? 'Checking…'
                          : release?.version ?? 'Unavailable',
                    ),
                    if (result != null)
                      Card(
                        child: ListTile(
                          leading: Icon(
                            _statusIcon(result.status),
                            color: _statusColor(result.status),
                          ),
                          title: const Text('Update Status'),
                          subtitle: Text(_statusLabel(result.status)),
                        ),
                      ),
                    if (_error != null)
                      Text(_error!, style: TextStyle(color: AppColors.danger)),
                    if (hasUpdate && release != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'What’s New',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        release.releaseNotes.trim().isEmpty
                            ? 'No release notes provided.'
                            : release.releaseNotes,
                      ),
                    ],
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _check,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check For Updates'),
                    ),
                    if (hasUpdate && release != null) ...[
                      FilledButton.icon(
                        onPressed: _isDiagnosing ? null : _update,
                        icon: const Icon(Icons.download),
                        label: Text('Update to ${release.version}'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isDiagnosing ? null : _validateUrl,
                        icon: _isDiagnosing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.link_outlined),
                        label: const Text('Validate Update URL'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Release History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_history.isEmpty && !_isLoading)
                      const Text('No release history is available.')
                    else
                      for (final item in _history)
                        Card(
                          child: ListTile(
                            title: Text('Version ${item.version}'),
                            subtitle: Text(
                              item.releaseNotes.trim().isEmpty
                                  ? 'No release notes provided.'
                                  : item.releaseNotes,
                            ),
                            trailing: Text(_formatDate(item.createdAt)),
                            isThreeLine: true,
                          ),
                        ),
                  ],
                ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.toLocal().year.toString().padLeft(4, '0')}-'
      '${date.toLocal().month.toString().padLeft(2, '0')}-'
      '${date.toLocal().day.toString().padLeft(2, '0')}';
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}
