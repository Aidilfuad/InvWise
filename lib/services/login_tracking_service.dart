import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';
import 'security_session_tracker.dart';

class LoginTrackingService {
  LoginTrackingService({
    ProfileService? profileService,
    SupabaseClient? client,
    SecuritySessionTracker? sessionTracker,
  }) : _profileService = profileService ?? ProfileService(),
       _client = client ?? Supabase.instance.client,
       _sessionTracker = sessionTracker ?? SecuritySessionTracker.instance;

  final ProfileService _profileService;
  final SupabaseClient _client;
  final SecuritySessionTracker _sessionTracker;

  Future<void> recordFailedLogin({
    required String attemptedIdentifier,
    required String failureReason,
  }) async {
    final identifier = attemptedIdentifier.trim();
    ProfileLookupResult? profile;
    if (identifier.contains('@')) {
      try {
        profile = await _profileService.getByEmail(identifier);
      } on ProfileServiceException catch (error) {
        debugPrint(
          '[LoginTrackingService] Could not resolve the failed login email: '
          '${error.message}',
        );
      }
    }
    if (profile == null) {
      try {
        profile = await _profileService.getByEmployeeId(identifier);
      } on ProfileServiceException catch (error) {
        debugPrint(
          '[LoginTrackingService] Could not resolve the failed login profile: '
          '${error.message}',
        );
      }
    }

    await _client.from('login_events').insert({
      'profile_id': profile?.id,
      'employee_id': profile?.employeeId ?? identifier,
      'succeeded': false,
      'failure_reason': failureReason,
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
      'user_agent': null,
      'ip_address': null,
    });
  }

  Future<void> recordSuccessfulLogin() async {
    final profile = await _profileService.getCurrentProfile();
    if (profile == null) {
      throw const LoginTrackingServiceException(
        'The signed-in user has no linked profile.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final trackingErrors = <String>[];

    try {
      await _client.from('login_events').insert({
        'profile_id': profile.id,
        'employee_id': profile.employeeId,
        'succeeded': true,
        'failure_reason': null,
        'occurred_at': now,
        'user_agent': null,
        'ip_address': null,
      });
    } on PostgrestException catch (error) {
      trackingErrors.add('login event: ${error.message}');
    }

    try {
      final session = await _client
          .from('device_sessions')
          .insert({
            'profile_id': profile.id,
            'device_name': _deviceName,
            'platform': _platformName,
            'user_agent': null,
            'ip_address': null,
            'started_at': now,
            'last_active_at': now,
          })
          .select('id')
          .single();
      final sessionId = session['id'];
      if (sessionId is! String || sessionId.isEmpty) {
        throw const FormatException(
          'The created device session did not return an id.',
        );
      }
      _sessionTracker.start(sessionId);
    } on PostgrestException catch (error) {
      trackingErrors.add('device session: ${error.message}');
    } on FormatException catch (error) {
      trackingErrors.add('device session: ${error.message}');
    }

    if (trackingErrors.isNotEmpty) {
      throw LoginTrackingServiceException(trackingErrors.join('; '));
    }
  }

  String get _platformName {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  String get _deviceName => '$_platformName device';
}

class LoginTrackingServiceException implements Exception {
  const LoginTrackingServiceException(this.message);

  final String message;

  @override
  String toString() => 'LoginTrackingServiceException: $message';
}
