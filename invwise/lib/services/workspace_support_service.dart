import 'package:supabase_flutter/supabase_flutter.dart';

class WorkspaceSupportService {
  WorkspaceSupportService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const String defaultSupportEmail = 'aidrusaidil@gmail.com';
  static const String _settingsId = 'exchange_rate_usd_myr';
  final SupabaseClient _client;

  Future<String> getSupportEmail() async {
    final row = await _client
        .from('app_settings')
        .select('support_email')
        .eq('id', _settingsId)
        .maybeSingle();
    final email = row?['support_email'] as String?;
    if (email == null || email.trim().isEmpty) {
      return defaultSupportEmail;
    }
    return email.trim();
  }

  Future<String> updateSupportEmail(String value) async {
    final email = value.trim().toLowerCase();
    if (email.length > 254 ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      throw ArgumentError('Enter a valid workspace support email address.');
    }
    final row = await _client
        .from('app_settings')
        .update({
          'support_email': email,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', _settingsId)
        .select('support_email')
        .maybeSingle();
    final savedEmail = row?['support_email'] as String?;
    if (savedEmail == null || savedEmail.isEmpty) {
      throw StateError(
        'The support email was not updated. Confirm that you are an active Super Admin.',
      );
    }
    return savedEmail;
  }

  RealtimeChannel subscribeToChanges(void Function(String email) onChange) =>
      _client
          .channel('workspace-support-email')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'app_settings',
            callback: (payload) {
              if (payload.newRecord['id'] != _settingsId) return;
              final email = payload.newRecord['support_email'];
              if (email is String && email.trim().isNotEmpty) {
                onChange(email.trim());
              }
            },
          )
          .subscribe();

  Future<void> removeChannel(RealtimeChannel channel) =>
      _client.removeChannel(channel);
}
