import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PasswordConfirmationService {
  const PasswordConfirmationService._();

  static Future<bool> confirm(
    BuildContext context, {
    required String action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PasswordConfirmationDialog(action: action),
    );
    return confirmed == true;
  }
}

class _PasswordConfirmationDialog extends StatefulWidget {
  const _PasswordConfirmationDialog({required this.action});

  final String action;

  @override
  State<_PasswordConfirmationDialog> createState() =>
      _PasswordConfirmationDialogState();
}

class _PasswordConfirmationDialogState
    extends State<_PasswordConfirmationDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      setState(() => _errorMessage = 'A signed-in email account is required.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: _controller.text)
          .timeout(const Duration(seconds: 15));
      if (mounted) Navigator.pop(context, true);
    } on AuthException {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = 'The password was not accepted.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = 'Password confirmation failed: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Confirm your password'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter your password to ${widget.action}.'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            enabled: !_saving,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Password is required' : null,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _confirmPassword,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Confirm'),
      ),
    ],
  );
}
