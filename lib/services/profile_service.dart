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
    this.authUserId,
    this.employeeId,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.department,
    this.position,
    this.role,
  });

  final String id;
  final String? authUserId;
  final String? employeeId;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? department;
  final String? position;
  final String? role;

  factory ProfileLookupResult.fromMap(Map<String, dynamic> map) {
    return ProfileLookupResult(
      id: map['id'] as String,
      authUserId: map['auth_user_id'] as String?,
      employeeId: map['employee_id'] as String?,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      phoneNumber: map['phone'] as String?,
      department: map['department'] as String?,
      position: map['position'] as String?,
      role: map['role'] as String?,
    );
  }
}

/// Reads and updates the current user's row in the `profiles` table.
class ProfileService {
  ProfileService();

  final SupabaseClient _client = Supabase.instance.client;

  static const String _table = 'profiles';

  Future<ProfileLookupResult?> getCurrentProfile() async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) return null;

    try {
      final row = await _client
          .from(_table)
          .select()
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      if (row == null) {
        throw const ProfileServiceException(
          'No profile is linked to the signed-in user.',
        );
      }
      final profileData = Map<String, dynamic>.from(row);
      profileData['email'] ??= _client.auth.currentUser?.email;
      return ProfileLookupResult.fromMap(profileData);
    } on PostgrestException catch (error) {
      throw ProfileServiceException(
        _friendlyMessage(error, 'load the current profile'),
      );
    } on ProfileServiceException {
      rethrow;
    } catch (_) {
      throw const ProfileServiceException(
        'Unable to load your profile. Please check your connection and try '
        'again.',
      );
    }
  }

  Future<ProfileLookupResult> updateCurrentProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) {
      throw const ProfileServiceException(
        'Sign in again before updating your profile.',
      );
    }
    final profile = await getCurrentProfile();
    if (profile == null) {
      throw const ProfileServiceException(
        'Sign in again before updating your profile.',
      );
    }

    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      throw const ProfileServiceException('Please enter your full name.');
    }

    try {
      final row = await _client
          .from(_table)
          .update({
            'full_name': trimmedName,
            'phone': _cleanOptional(phoneNumber),
          })
          .eq('id', profile.id)
          .eq('auth_user_id', authUserId)
          .select()
          .maybeSingle();
      if (row == null) {
        throw const ProfileServiceException(
          'Profile was not updated. Check your access and try again.',
        );
      }
      final profileData = Map<String, dynamic>.from(row);
      profileData['email'] ??= _client.auth.currentUser?.email;
      return ProfileLookupResult.fromMap(profileData);
    } on PostgrestException catch (error) {
      throw ProfileServiceException(
        _friendlyMessage(error, 'update the profile'),
      );
    } on ProfileServiceException {
      rethrow;
    } catch (_) {
      throw const ProfileServiceException(
        'Unable to update your profile. Please check your connection and try '
        'again.',
      );
    }
  }

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
    } on PostgrestException catch (error) {
      throw ProfileServiceException(
        _friendlyMessage(error, 'look up the employee profile'),
      );
    } catch (_) {
      throw const ProfileServiceException(
        'Unable to look up the employee profile. '
        'Please check your connection and try again.',
      );
    }
  }

  /// Finds the profile whose `email` equals [email].
  ///
  /// Returns null when no record exists or [email] is empty.
  /// Throws [ProfileServiceException] if the lookup fails.
  Future<ProfileLookupResult?> getByEmail(String email) async {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic>? row = await _client
          .from(_table)
          .select()
          .eq('email', trimmedEmail)
          .limit(1)
          .maybeSingle();

      if (row == null) {
        return null;
      }

      return ProfileLookupResult.fromMap(row);
    } on PostgrestException catch (error) {
      throw ProfileServiceException(
        _friendlyMessage(error, 'look up the email profile'),
      );
    } catch (_) {
      throw const ProfileServiceException(
        'Unable to look up the email profile. '
        'Please check your connection and try again.',
      );
    }
  }

  String? _cleanOptional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _friendlyMessage(PostgrestException error, String action) {
    if (error.code == '42501' ||
        error.message.toLowerCase().contains('row-level security')) {
      return 'You do not have permission to $action.';
    }
    if (error.code == '23503') {
      return 'A referenced profile value is invalid. Check the profile data.';
    }
    return 'Unable to $action. ${error.message}';
  }
}
