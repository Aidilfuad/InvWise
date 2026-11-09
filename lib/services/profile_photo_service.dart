import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';

class ProfilePhotoServiceException implements Exception {
  const ProfilePhotoServiceException(this.message);

  final String message;

  @override
  String toString() => 'ProfilePhotoServiceException: $message';
}

class ProfilePhotoUpdateResult {
  const ProfilePhotoUpdateResult({
    required this.profile,
    this.previousPhotoCleanupFailed = false,
    this.profileCacheUpdateFailed = false,
  });

  final ProfileLookupResult profile;
  final bool previousPhotoCleanupFailed;
  final bool profileCacheUpdateFailed;
}

class ProfilePhotoService {
  ProfilePhotoService({SupabaseClient? client, ProfileService? profileService})
    : _client = client ?? Supabase.instance.client,
      _profileService =
          profileService ??
          ProfileService(client: client ?? Supabase.instance.client);

  static const String bucketName = 'profile-photos';
  static const int avatarSize = 512;
  static const int maxPhotoBytes = 5 * 1024 * 1024;
  static final RegExp _photoPathPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/'
    r'[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|png|webp)$',
    caseSensitive: false,
  );

  final SupabaseClient _client;
  final ProfileService _profileService;

  Future<ProfilePhotoUpdateResult> upload({
    required Uint8List croppedJpeg,
    required ProfileLookupResult profile,
  }) async {
    final userId = _requireCurrentUser(profile);
    debugPrint('[ProfilePhotoService] Validating cropped JPEG.');
    final size = croppedJpeg.length;
    if (size == 0 || size > maxPhotoBytes) {
      throw const ProfilePhotoServiceException(
        'The cropped profile photo must be smaller than 5 MB.',
      );
    }

    if (!isValidCroppedJpeg(croppedJpeg)) {
      throw const ProfilePhotoServiceException(
        'Only cropped 512 × 512 JPEG avatars can be uploaded.',
      );
    }
    final decoded = img.decodeImage(croppedJpeg)!;

    final objectPath = '$userId/${_newUuid()}.jpg';
    debugPrint(
      '[ProfilePhotoService] Uploading bucket=$bucketName, '
      'path=$objectPath, bytes=$size, contentType=image/jpeg, '
      'dimensions=${decoded.width}x${decoded.height}',
    );
    try {
      await _client.storage
          .from(bucketName)
          .uploadBinary(
            objectPath,
            croppedJpeg,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );
      debugPrint('[ProfilePhotoService] Storage upload completed.');
    } on StorageException catch (error, stackTrace) {
      debugPrint(
        '[ProfilePhotoService] Storage upload failed: $error\n$stackTrace',
      );
      throw ProfilePhotoServiceException(
        'Unable to upload your photo. Supabase Storage error: $error',
      );
    }

    late final ProfileAvatarUpdate avatarUpdate;
    try {
      debugPrint(
        '[ProfilePhotoService] Calling update_current_profile_avatar '
        'with path=$objectPath.',
      );
      avatarUpdate = await _profileService.updateCurrentAvatar(objectPath);
      debugPrint('[ProfilePhotoService] Profile avatar RPC completed.');
    } catch (error) {
      debugPrint('[ProfilePhotoService] Profile avatar RPC failed: $error');
      try {
        await _client.storage.from(bucketName).remove([objectPath]);
      } on StorageException {
        throw const ProfilePhotoServiceException(
          'The profile could not be updated and the uploaded photo could not '
          'be cleaned up. Contact an administrator.',
        );
      }
      if (error is ProfileServiceException) {
        throw ProfilePhotoServiceException(error.message);
      }
      rethrow;
    }

    final previousPath = _ownedPath(avatarUpdate.previousAvatarUrl, userId);
    var cleanupFailed = false;
    if (previousPath != null && previousPath != objectPath) {
      try {
        await _client.storage.from(bucketName).remove([previousPath]);
      } on StorageException {
        cleanupFailed = true;
      }
    }
    return ProfilePhotoUpdateResult(
      profile: avatarUpdate.profile,
      previousPhotoCleanupFailed: cleanupFailed,
      profileCacheUpdateFailed: avatarUpdate.cacheUpdateFailed,
    );
  }

  Future<ProfilePhotoUpdateResult> remove({
    required ProfileLookupResult profile,
  }) async {
    final userId = _requireCurrentUser(profile);
    final update = await _profileService.updateCurrentAvatar(null);
    final previousPath = _ownedPath(update.previousAvatarUrl, userId);
    var cleanupFailed = false;
    if (previousPath != null) {
      try {
        await _client.storage.from(bucketName).remove([previousPath]);
      } on StorageException {
        cleanupFailed = true;
      }
    }
    return ProfilePhotoUpdateResult(
      profile: update.profile,
      previousPhotoCleanupFailed: cleanupFailed,
      profileCacheUpdateFailed: update.cacheUpdateFailed,
    );
  }

  String _requireCurrentUser(ProfileLookupResult profile) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null ||
        profile.authUserId == null ||
        profile.authUserId != userId) {
      throw const ProfilePhotoServiceException(
        'Sign in again before changing your profile photo.',
      );
    }
    return userId;
  }

  String? _ownedPath(String? value, String userId) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value);
    final segments = uri?.hasScheme == true
        ? uri!.pathSegments
        : value.split('/');
    final bucketIndex = segments.indexOf(bucketName);
    final path = bucketIndex >= 0
        ? segments.skip(bucketIndex + 1).join('/')
        : segments.join('/');
    if (!_photoPathPattern.hasMatch(path) || !path.startsWith('$userId/')) {
      return null;
    }
    return path;
  }

  static Uint8List encodeCroppedJpeg(Uint8List croppedBytes) {
    final decoded = img.decodeImage(croppedBytes);
    if (decoded == null) {
      throw const ProfilePhotoServiceException(
        'The cropper returned an unreadable image.',
      );
    }
    if (decoded.width != decoded.height) {
      throw const ProfilePhotoServiceException('The crop area must be square.');
    }

    final resized = img.copyResize(
      decoded,
      width: avatarSize,
      height: avatarSize,
      interpolation: img.Interpolation.average,
    );
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  static bool isValidCroppedJpeg(Uint8List bytes) {
    if (!_isJpeg(bytes)) return false;
    final decoded = img.decodeImage(bytes);
    return decoded?.width == avatarSize && decoded?.height == avatarSize;
  }

  static bool _isJpeg(Uint8List bytes) =>
      bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff;

  String _newUuid() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
