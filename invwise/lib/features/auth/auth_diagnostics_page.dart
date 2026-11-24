import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';

/// TEMPORARY developer-only page used to verify the Supabase connection
/// before integrating login. Remove before release.
class AuthDiagnosticsPage extends StatefulWidget {
  const AuthDiagnosticsPage({super.key});

  @override
  State<AuthDiagnosticsPage> createState() => _AuthDiagnosticsPageState();
}

class _DiagnosticsResult {
  const _DiagnosticsResult({
    required this.sessionConnected,
    required this.projectConnected,
    required this.errors,
    required this.checkedAt,
  });

  final bool sessionConnected;
  final bool projectConnected;
  final List<String> errors;
  final DateTime checkedAt;
}

class _AuthDiagnosticsPageState extends State<AuthDiagnosticsPage> {
  bool _loading = false;
  _DiagnosticsResult? _result;

  Future<void> _onTestConnection() async {
    setState(() => _loading = true);

    final errors = <String>[];
    var sessionConnected = false;
    var projectConnected = false;

    // 1. Session check.
    try {
      final session = Supabase.instance.client.auth.currentSession;
      sessionConnected = session != null;
    } catch (e) {
      errors.add('Session check failed: ${e.runtimeType}: $e');
    }

    // 2. Project reachability check (valid URL + anon key).
    try {
      await Supabase.instance.client
          .from('profiles')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      projectConnected = true;
    } on PostgrestException catch (e) {
      errors.add(
        'Project check failed (Postgrest ${e.code ?? 'no code'}): ${e.message}',
      );
    } catch (e) {
      errors.add('Project check failed: ${e.runtimeType}: $e');
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
      _result = _DiagnosticsResult(
        sessionConnected: sessionConnected,
        projectConnected: projectConnected,
        errors: errors,
        checkedAt: DateTime.now(),
      );
    });
  }

  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Auth Diagnostics')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: _loading ? null : _onTestConnection,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Test Connection'),
              ),
              const SizedBox(height: 16),
              if (result == null)
                _ResultCard(
                  children: [
                    Text(
                      'Press "Test Connection" to run the check.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                )
              else
                _ResultCard(
                  children: [
                    _ResultRow(
                      label: 'Session',
                      value: result.sessionConnected
                          ? 'Connected'
                          : 'Not Connected',
                      ok: result.sessionConnected,
                    ),
                    const SizedBox(height: 12),
                    _ResultRow(
                      label: 'Project connected',
                      value: result.projectConnected ? 'Yes' : 'No',
                      ok: result.projectConnected,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Checked at ${_formatTime(result.checkedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (result.errors.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Errors',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final error in result.errors) ...[
                        SelectableText(
                          error,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Icon(
          ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 18,
          color: ok ? AppColors.success : AppColors.danger,
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ok ? AppColors.success : AppColors.danger,
          ),
        ),
      ],
    );
  }
}