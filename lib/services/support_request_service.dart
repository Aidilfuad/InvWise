import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';

class SupportRequestServiceException implements Exception {
  const SupportRequestServiceException(this.message);

  final String message;

  @override
  String toString() => 'SupportRequestServiceException: $message';
}

class SupportRequestSubmissionResult {
  const SupportRequestSubmissionResult({
    required this.notificationSent,
    this.notificationError,
  });

  final bool notificationSent;
  final String? notificationError;
}

class SupportRequestService {
  SupportRequestService({
    ProfileService? profileService,
    SupabaseClient? client,
  }) : _profileService = profileService ?? ProfileService(),
       _client = client ?? Supabase.instance.client;

  static const String _table = 'support_requests';

  final ProfileService _profileService;
  final SupabaseClient _client;

  Future<SupportRequestSubmissionResult> createRequest({
    required String subject,
    required String message,
  }) async {
    final trimmedSubject = subject.trim();
    final trimmedMessage = message.trim();
    if (trimmedSubject.isEmpty || trimmedMessage.isEmpty) {
      throw const SupportRequestServiceException(
        'Enter a subject and describe the issue.',
      );
    }

    try {
      final profile = await _profileService.getCurrentProfile();
      if (profile == null) {
        throw const SupportRequestServiceException(
          'Sign in to submit a support request.',
        );
      }

      final request = await _client
          .from(_table)
          .insert({
            'profile_id': profile.id,
            'subject': trimmedSubject,
            'message': trimmedMessage,
          })
          .select('id')
          .single();

      try {
        final response = await _client.functions.invoke(
          'notify-support-request',
          body: {'request_id': request['id']},
        );
        final data = response.data;
        if (data is Map && data['notification_sent'] == true) {
          return const SupportRequestSubmissionResult(notificationSent: true);
        }
        return const SupportRequestSubmissionResult(
          notificationSent: false,
          notificationError:
              'The notification service did not confirm delivery.',
        );
      } catch (error) {
        return SupportRequestSubmissionResult(
          notificationSent: false,
          notificationError: error.toString(),
        );
      }
    } on ProfileServiceException catch (error) {
      throw SupportRequestServiceException(error.message);
    } on PostgrestException catch (error) {
      throw SupportRequestServiceException(_friendlyMessage(error));
    }
  }

  String _friendlyMessage(PostgrestException error) {
    if (error.code == '42501' ||
        error.message.toLowerCase().contains('row-level security')) {
      return 'You do not have permission to submit a support request.';
    }
    if (error.code == '23503') {
      return 'Your profile could not be linked to the support request.';
    }
    return 'Unable to submit your support request. ${error.message}';
  }
}
