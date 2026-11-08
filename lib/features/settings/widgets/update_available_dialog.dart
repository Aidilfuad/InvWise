import 'package:flutter/material.dart';

import '../../../services/app_update_service.dart';

class UpdateAvailableDialog extends StatefulWidget {
  const UpdateAvailableDialog({
    required this.release,
    required this.service,
    super.key,
  });

  final AppVersionRelease release;
  final AppUpdateService service;

  @override
  State<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<UpdateAvailableDialog> {
  bool _opening = false;
  bool _opened = false;
  String? _error;

  Future<void> _openUpdate() async {
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      await widget.service.launchUpdate(widget.release);
      if (mounted) setState(() => _opened = true);
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to open update: $error');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.release.forceUpdate || _opened,
    child: AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.release.forceUpdate
                  ? 'Update Required'
                  : 'Update Available',
            ),
          ),
          if (_opened)
            IconButton(
              tooltip: 'Close update dialog',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text('Version: ${widget.release.version}'),
            const SizedBox(height: 12),
            const Text('What’s New'),
            const SizedBox(height: 4),
            Text(
              widget.release.releaseNotes.trim().isEmpty
                  ? 'No release notes provided.'
                  : widget.release.releaseNotes,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_opened) ...[
              const SizedBox(height: 12),
              const Text(
                'Update download started. Complete installation and reopen InvWise.',
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!widget.release.forceUpdate)
          TextButton(
            onPressed: _opening ? null : () => Navigator.pop(context),
            child: const Text('Later'),
          ),
        FilledButton.icon(
          onPressed: _opening || _opened ? null : _openUpdate,
          icon: _opening
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          label: Text(
            _opening
                ? 'Opening…'
                : _opened
                ? '✓ Download Started'
                : 'Update Now',
          ),
        ),
      ],
    ),
  );
}
