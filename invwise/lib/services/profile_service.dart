import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import 'offline_cache_service.dart';

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
    this.avatarUrl,
    this.isActive = true,
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
  final String? avatarUrl;
  final bool isActive;

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
      avatarUrl: map['avatar_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  factory ProfileLookupResult.fromCacheMap(Map<String, dynamic> map) =>
      ProfileLookupResult(
        id: map['id'] as String,
        authUserId: map['authUserId'] as String?,
        employeeId: map['employeeId'] as String?,
        fullName: map['fullName'] as String?,
        email: map['email'] as String?,
        phoneNumber: map['phoneNumber'] as String?,
        department: map['department'] as String?,
        position: map['position'] as String?,
        role: map['role'] as String?,
        avatarUrl: map['avatarUrl'] as String?,
        isActive: map['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toCacheMap() => {
    'id': id,
    'authUserId': authUserId,
    'employeeId': employeeId,
    'fullName': fullName,
    'email': email,
    'phoneNumber': phoneNumber,
    'department': department,
    'position': position,
    'role': role,
    'avatarUrl': avatarUrl,
    'isActive': isActive,
  };

  ProfileLookupResult copyWithAvatarUrl(String? value) => ProfileLookupResult(
    id: id,
    authUserId: authUserId,
    employeeId: employeeId,
    fullName: fullName,
    email: email,
    phoneNumber: phoneNumber,
    department: department,
    position: position,
    role: role,
    avatarUrl: value,
    isActive: isActive,
  );
}

class ProfileAvatarUpdate {
  const ProfileAvatarUpdate({
    required this.profile,
    required this.previousAvatarUrl,
    this.cacheUpdateFailed = false,
  });

  final ProfileLookupResult profile;
  final String? previousAvatarUrl;
  final bool cacheUpdateFailed;
}

/// Reads and updates the current user's row in the `profiles` table.
class ProfileService {
  ProfileService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'profiles';

  Future<ProfileLookupResult?> getCurrentProfile() async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) return null;
    return OfflineCacheService.instance.loadValue<ProfileLookupResult>(
      key: 'profile.current',
      scopeId: authUserId,
      decode: (value) => ProfileLookupResult.fromCacheMap(
        Map<String, dynamic>.from(value as Map),
      ),
      encode: (profile) => profile.toCacheMap(),
      fetchRemote: () => _fetchCurrentProfile(authUserId),
    );
  }

  Future<ProfileLookupResult> _fetchCurrentProfile(String authUserId) async {
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
      final updatedProfile = ProfileLookupResult.fromMap(profileData);
      await OfflineCacheService.instance.writeValue(
        'profile.current',
        updatedProfile.toCacheMap(),
        scopeId: authUserId,
      );
      if (!updatedProfile.isActive) {
        throw const ProfileServiceException(
          'This account is inactive. Contact a Super Admin.',
        );
      }
      return updatedProfile;
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
      final updatedProfile = ProfileLookupResult.fromMap(profileData);
      await OfflineCacheService.instance.writeValue(
        'profile.current',
        updatedProfile.toCacheMap(),
        scopeId: authUserId,
      );
      return updatedProfile;
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

  Future<ProfileAvatarUpdate> updateCurrentAvatar(String? objectPath) async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) {
      throw const ProfileServiceException(
        'Sign in again before changing your profile photo.',
      );
    }

    try {
      final currentProfile = await getCurrentProfile();
      if (currentProfile == null) {
        throw const ProfileServiceException(
          'Sign in again before changing your profile photo.',
        );
      }
      final response = await _client.rpc(
        'update_current_profile_avatar',
        params: {'p_object_path': objectPath},
      );
      if (response is! Map) {
        throw const ProfileServiceException(
          'The profile photo update returned an invalid response.',
        );
      }

      final result = Map<String, dynamic>.from(response);
      final updatedProfile = currentProfile.copyWithAvatarUrl(
        result['avatar_url'] as String?,
      );
      var cacheUpdateFailed = false;
      try {
        await OfflineCacheService.instance.writeValue(
          'profile.current',
          updatedProfile.toCacheMap(),
          scopeId: authUserId,
        );
      } catch (_) {
        cacheUpdateFailed = true;
      }
      return ProfileAvatarUpdate(
        profile: updatedProfile,
        previousAvatarUrl: result['previous_avatar_url'] as String?,
        cacheUpdateFailed: cacheUpdateFailed,
      );
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[ProfileService] update_current_profile_avatar RPC failed: '
        '$error\n$stackTrace',
      );
      throw ProfileServiceException(
        '${_friendlyMessage(error, 'update the profile photo')} '
        'RPC error: $error',
      );
    } on ProfileServiceException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint(
        '[ProfileService] Profile photo update failed: '
        '$error\n$stackTrace',
      );
      throw ProfileServiceException(
        'Unable to update your profile photo: $error',
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
