import 'package:supabase_flutter/supabase_flutter.dart';

/// Error thrown by [ProfileService] with a message that is safe to show in
/// the UI.
class ProfileServiceException implements Exception {
  const ProfileServiceException(this.message);

  final String message;

  @override
  String toString() => 'ProfileServiceException: $message';
}

/// A row of the `profiles` table.
class ProfileLookupResult {
  const ProfileLookupResult({
    required this.id,
    required this.employeeId,
    this.authUserId,
    this.fullName,
    this.email,
    this.phone,
  });

  final String id;
  final String? authUserId;
  final String employeeId;
  final String? fullName;
  final String? email;
  final String? phone;

  factory ProfileLookupResult.fromMap(Map<String, dynamic> map) {
    return ProfileLookupResult(
      id: map['id'] as String,
      authUserId: map['auth_user_id'] as String?,
      employeeId: map['employee_id'] as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
    );
  }
}

/// Reads profile data from the `profiles` table.
class ProfileService {
  ProfileService();

  final SupabaseClient _client = Supabase.instance.client;

  static const String _table = 'profiles';

  /// Finds the profile whose `employee_id` equals [employeeId].
  ///
  /// Returns null when no record exists or [employeeId] is empty.
  /// Throws [ProfileServiceException] if the lookup fails.
  Future<ProfileLookupResult?> getByEmployeeId(String employeeId) async {
    final trimmedId = employeeId.trim();

    if (trimmedId.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic>? row = await _client
          .from(_table)
          .select()
          .eq('employee_id', trimmedId)
          .limit(1)
          .maybeSingle();

      if (row == null) {
        return null;
      }

      return ProfileLookupResult.fromMap(row);
    } on PostgrestException {
      throw const ProfileServiceException(
        'Unable to look up the employee profile. Please try again.',
      );
    } catch (_) {
      throw const ProfileServiceException(
        'Unable to look up the employee profile. '
        'Please check your connection and try again.',
      );
    }
  }
}