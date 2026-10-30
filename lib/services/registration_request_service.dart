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

  static const String _table = 'registration_requests';
  static const Set<String> requestedRoles = {
    'Warehouse Supervisor',
    'Storekeeper',
  };

  final SupabaseClient _client;

  Future<void> submitRequest({
    required String fullName,
    required String employeeId,
    required String email,
    required String department,
    required String requestedRole,
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
    if (!requestedRoles.contains(requestedRole)) {
      throw const RegistrationRequestServiceException(
        'Select a valid requested role.',
      );
    }

    try {
      await _client.from(_table).insert({
        'full_name': trimmedName,
        'employee_id': trimmedEmployeeId,
        'email': trimmedEmail,
        'department': trimmedDepartment,
        'requested_role': requestedRole,
        'status': 'pending',
      });
    } on PostgrestException catch (error) {
      throw RegistrationRequestServiceException(_friendlyMessage(error));
    } catch (error) {
      throw RegistrationRequestServiceException(
        'Unable to submit your registration request. $error',
      );
    }
  }

  String _friendlyMessage(PostgrestException error) {
    if (error.code == '42501' ||
        error.message.toLowerCase().contains('row-level security')) {
      return 'Registration requests are currently unavailable. Please try '
          'again later.';
    }
    if (error.code == '22P02' || error.code == '23514') {
      return 'The requested role or request status is invalid.';
    }
    return 'Unable to submit your registration request. ${error.message}';
  }
}
