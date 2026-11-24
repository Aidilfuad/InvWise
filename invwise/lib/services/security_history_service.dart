import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';
import 'security_session_tracker.dart';

class SecurityHistoryServiceException implements Exception {
  const SecurityHistoryServiceException(this.message);

  final String message;

  @override
  String toString() => 'SecurityHistoryServiceException: $message';
}

class LoginEvent {
  const LoginEvent({
    required this.id,
    required this.succeeded,
    required this.occurredAt,
    this.failureReason,
    this.ipAddress,
    this.userAgent,
  });

  final String id;
  final bool succeeded;
  final DateTime occurredAt;
  final String? failureReason;
  final String? ipAddress;
  final String? userAgent;

  factory LoginEvent.fromMap(Map<String, dynamic> map) {
    final occurredAt = DateTime.tryParse(map['occurred_at'] as String? ?? '');
    if (occurredAt == null) {
      throw const FormatException('Login event has an invalid timestamp.');
    }
    return LoginEvent(
      id: _requiredString(map, 'id'),
      succeeded: map['succeeded'] as bool,
      occurredAt: occurredAt,
      failureReason: map['failure_reason'] as String?,
      ipAddress: map['ip_address'] as String?,
      userAgent: map['user_agent'] as String?,
    );
  }
}

class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.lastActiveAt,
    this.userAgent,
    this.ipAddress,
    this.startedAt,
    this.isCurrentSession = false,
  });

  final String id;
  final String deviceName;
  final String platform;
  final DateTime? lastActiveAt;
  final String? userAgent;
  final String? ipAddress;
  final DateTime? startedAt;
  final bool isCurrentSession;

  factory DeviceSession.fromMap(Map<String, dynamic> map) => DeviceSession(
    id: _requiredString(map, 'id'),
    deviceName: _displayValue(map['device_name']),
    platform: _displayValue(map['platform']),
    lastActiveAt: _dateValue(map['last_active_at']),
    userAgent: map['user_agent'] as String?,
    ipAddress: map['ip_address'] as String?,
    startedAt: _dateValue(map['started_at']),
    isCurrentSession: map['is_current_session'] as bool? ?? false,
  );
}

class SecurityHistoryService {
  SecurityHistoryService({
    ProfileService? profileService,
    SupabaseClient? client,
  }) : _profileService = profileService ?? ProfileService(),
       _client = client ?? Supabase.instance.client;

  final ProfileService _profileService;
  final SupabaseClient _client;

  Future<LoginEvent?> getLatestSuccessfulLogin() async {
    final profileId = await _currentProfileId();
    try {
      final row = await _client
          .from('login_events')
          .select(
            'id,profile_id,employee_id,succeeded,failure_reason,ip_address,'
            'user_agent,occurred_at',
          )
          .eq('profile_id', profileId)
          .eq('succeeded', true)
          .order('occurred_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : LoginEvent.fromMap(row);
    } on PostgrestException catch (error) {
      throw SecurityHistoryServiceException(
        _friendlyMessage(error, 'load the last successful login'),
      );
    } on FormatException catch (error) {
      throw SecurityHistoryServiceException(error.message);
    } catch (error) {
      if (error is SecurityHistoryServiceException) rethrow;
      throw SecurityHistoryServiceException(
        'Unable to load the last successful login. Please try again. ($error)',
      );
    }
  }

  Future<List<LoginEvent>> getLoginHistory({int limit = 100}) async {
    if (limit <= 0) {
      throw const SecurityHistoryServiceException(
        'The login history result limit must be greater than zero.',
      );
    }
    final profileId = await _currentProfileId();
    try {
      final rows = await _client
          .from('login_events')
          .select(
            'id,profile_id,employee_id,succeeded,failure_reason,ip_address,'
            'user_agent,occurred_at',
          )
          .eq('profile_id', profileId)
          .order('occurred_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);
      return rows.map<LoginEvent>(LoginEvent.fromMap).toList(growable: false);
    } on PostgrestException catch (error) {
      throw SecurityHistoryServiceException(
        _friendlyMessage(error, 'load login history'),
      );
    } on FormatException catch (error) {
      throw SecurityHistoryServiceException(error.message);
    } catch (error) {
      if (error is SecurityHistoryServiceException) rethrow;
      throw SecurityHistoryServiceException(
        'Unable to load login history. Please try again. ($error)',
      );
    }
  }

  Future<List<DeviceSession>> getActiveSessions() async {
    final profileId = await _currentProfileId();
    try {
      final rows = await _client
          .from('device_sessions')
          .select(
            'id,profile_id,device_name,platform,user_agent,ip_address,'
            'started_at,last_active_at,revoked_at',
          )
          .eq('profile_id', profileId)
          .isFilter('revoked_at', null)
          .order('last_active_at', ascending: false)
          .order('id', ascending: false);
      final currentSessionRowId =
          SecuritySessionTracker.instance.currentSessionRowId;
      return rows
          .map<DeviceSession>(
            (row) => DeviceSession.fromMap({
              ...row,
              'is_current_session': row['id'] == currentSessionRowId,
            }),
          )
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw SecurityHistoryServiceException(
        _friendlyMessage(error, 'load active sessions'),
      );
    } on FormatException catch (error) {
      throw SecurityHistoryServiceException(error.message);
    } catch (error) {
      if (error is SecurityHistoryServiceException) rethrow;
      throw SecurityHistoryServiceException(
        'Unable to load active sessions. Please try again. ($error)',
      );
    }
  }

  Future<String> _currentProfileId() async {
    try {
      final profile = await _profileService.getCurrentProfile();
      if (profile == null) {
        throw const SecurityHistoryServiceException(
          'Sign in to view your security history.',
        );
      }
      return profile.id;
    } on ProfileServiceException catch (error) {
      throw SecurityHistoryServiceException(error.message);
    }
  }

  String _friendlyMessage(PostgrestException error, String action) {
    if (error.code == '42501' ||
        error.message.toLowerCase().contains('row-level security')) {
      return 'You do not have permission to $action.';
    }
    if (error.code == 'PGRST301' ||
        error.message.toLowerCase().contains('jwt')) {
      return 'Your session has expired. Please sign in again.';
    }
    return 'Unable to $action. ${error.message}';
  }
}

String _requiredString(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Security history row is missing $field.');
}

String _displayValue(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : 'Unknown';

DateTime? _dateValue(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
