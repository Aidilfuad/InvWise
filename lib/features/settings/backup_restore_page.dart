import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/settings_backup_service.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key, this.service});

  final SettingsBackupService? service;

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  late final SettingsBackupService _service =
      widget.service ?? SettingsBackupService();
  bool _working = false;

  Future<void> _export() async {
    await _run('Export', () async {
      final json = await _service.exportJson();
      await SharePlus.instance.share(
        ShareParams(
          title: 'InvWise Settings Backup',
          subject: 'InvWise Settings Backup',
          text: json,
        ),
      );
    });
  }

  Future<void> _import() async {
    final controller = TextEditingController();
    final json = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Settings'),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Paste settings backup JSON',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (json == null || json.trim().isEmpty) return;
    await _run('Import', () => _service.importJson(json));
  }

  Future<void> _restoreDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore default settings?'),
        content: const Text(
          'This resets currency, telemetry, theme, language, and dashboard '
          'preferences for your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore Defaults'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run('Restore defaults', _service.restoreDefaults);
  }

  Future<void> _run(String action, Future<void> Function() task) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await task();
      if (mounted) _message('$action completed.');
    } catch (error) {
      if (mounted) _message('$action failed: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Backup & Restore Settings')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1600),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Backup scope: currency settings, telemetry settings, user '
              'preferences, and dashboard preferences.',
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _working ? null : _export,
              icon: const Icon(Icons.ios_share),
              label: const Text('Export Settings'),
            ),
            OutlinedButton.icon(
              onPressed: _working ? null : _import,
              icon: const Icon(Icons.input),
              label: const Text('Import Settings'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _working ? null : _restoreDefaults,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restore Default Settings'),
            ),
            if (_working) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    ),
  );
}
