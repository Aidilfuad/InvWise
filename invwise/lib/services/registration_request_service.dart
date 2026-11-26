import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationRequestServiceException implements Exception {
  const RegistrationRequestServiceException(this.message);

  final String message;

  @override
  String toString() => 'RegistrationRequestServiceException: $message';
}

class RegistrationRequestService {
  RegistrationRequestService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> submitRequest({
    required String fullName,
    required String employeeId,
    required String email,
    required String department,
    required String requestedRole,
    required String password,
    String? reason,
  }) async {
    final trimmedName = fullName.trim();
    final trimmedEmployeeId = employeeId.trim();
    final trimmedEmail = email.trim();
    final trimmedDepartment = department.trim();
    if (trimmedName.isEmpty ||
        trimmedEmployeeId.isEmpty ||
        trimmedEmail.isEmpty ||
        trimmedDepartment.isEmpty) {
      throw const RegistrationRequestServiceException(
        'Complete all required registration request fields.',
      );
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmedEmail)) {
      throw const RegistrationRequestServiceException(
        'Enter a valid email address.',
      );
    }
    try {
      final response = await _client.functions.invoke(
        'submit-registration-request',
        body: {
          'full_name': trimmedName,
          'employee_id': trimmedEmployeeId,
          'email': trimmedEmail,
          'department': trimmedDepartment,
          'requested_role': requestedRole,
          'reason': reason?.trim() ?? '',
          'password': password,
        },
      );
      if (response.status < 200 || response.status >= 300) {
        final message = response.data is Map
            ? (response.data as Map)['error']?.toString()
            : null;
        throw RegistrationRequestServiceException(
          message ?? 'Registration request service returned HTTP ${response.status}.',
        );
      }
      if (response.data is! Map ||
          (response.data as Map)['status'] != 'pending' ||
          (response.data as Map)['request_id'] is! String) {
        throw const RegistrationRequestServiceException(
          'The registration service did not confirm that your request was saved.',
        );
      }
    } on FunctionException catch (error) {
      final details = error.details;
      final message = details is Map ? details['error']?.toString() : null;
      throw RegistrationRequestServiceException(
        message ?? 'Registration request service returned HTTP ${error.status}.',
      );
    } catch (error) {
      if (error is RegistrationRequestServiceException) rethrow;
      throw RegistrationRequestServiceException(
        'Unable to submit your registration request. $error',
      );
    }
  }
}
