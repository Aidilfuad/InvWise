import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/constants/app_colors.dart';
import '../services/profile_photo_service.dart';
import '../services/profile_service.dart';
import 'profile_avatar.dart';
import 'profile_photo_crop_screen.dart';

class ProfilePhotoEditor extends StatefulWidget {
  const ProfilePhotoEditor({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
    this.photoService,
    this.imagePicker,
    this.avatarSize = 72,
  });

  final ProfileLookupResult profile;
  final ValueChanged<ProfileLookupResult> onProfileUpdated;
  final ProfilePhotoService? photoService;
  final ImagePicker? imagePicker;
  final double avatarSize;

  @override
  State<ProfilePhotoEditor> createState() => _ProfilePhotoEditorState();
}

class _ProfilePhotoEditorState extends State<ProfilePhotoEditor> {
  late ProfileLookupResult _profile = widget.profile;
  late final ProfilePhotoService _photoService =
      widget.photoService ?? ProfilePhotoService();
  late final ImagePicker _imagePicker = widget.imagePicker ?? ImagePicker();
  bool _isBusy = false;

  bool get _supportsCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void didUpdateWidget(covariant ProfilePhotoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) _profile = widget.profile;
  }

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_supportsCamera)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    debugPrint('[ProfilePhotoEditor] Picker starting; source=$source');
    var failedStep = 'image picker';
    setState(() => _isBusy = true);
    try {
      final file = await _imagePicker.pickImage(source: source);
      if (file == null) {
        debugPrint('[ProfilePhotoEditor] Picker returned no file (cancelled).');
        return;
      }
      debugPrint(
        '[ProfilePhotoEditor] Picker returned file name=${file.name}, '
        'path=${file.path}',
      );
      if (!mounted) return;
      failedStep = 'selected file inspection';
      final sourceBytes = await file.readAsBytes();
      debugPrint(
        '[ProfilePhotoEditor] Read ${sourceBytes.length} source bytes.',
      );
      if (!mounted) return;

      failedStep = 'photo crop';
      final croppedJpeg = await ProfilePhotoCropScreen.open(
        context,
        imageBytes: sourceBytes,
      );
      if (croppedJpeg == null || !mounted) return;
      debugPrint(
        '[ProfilePhotoEditor] Crop output=${croppedJpeg.length} bytes.',
      );

      failedStep = 'photo upload and profile update';
      final result = await _photoService.upload(
        croppedJpeg: croppedJpeg,
        profile: _profile,
      );
      if (!mounted) return;
      _updateProfile(result);
      _showMessage(
        _successMessage(
          'Profile photo updated.',
          result,
          cleanupLabel: 'The previous photo could not be removed.',
        ),
      );
    } on ProfilePhotoServiceException catch (error) {
      debugPrint('[ProfilePhotoEditor] Profile photo service failed: $error');
      if (mounted) _showMessage(error.message);
    } catch (error, stackTrace) {
      debugPrint(
        '[ProfilePhotoEditor] Photo selection/upload failed: '
        '$error\n$stackTrace',
      );
      if (mounted) {
        _showMessage('Profile photo $failedStep failed: $error');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _removePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text('Your initials will appear instead of the photo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove photo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final result = await _photoService.remove(profile: _profile);
      if (!mounted) return;
      _updateProfile(result);
      _showMessage(
        _successMessage(
          'Profile photo removed.',
          result,
          cleanupLabel: 'The stored image could not be deleted.',
        ),
      );
    } on ProfilePhotoServiceException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to remove the photo. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _updateProfile(ProfilePhotoUpdateResult result) {
    setState(() => _profile = result.profile);
    widget.onProfileUpdated(result.profile);
  }

  String _successMessage(
    String success,
    ProfilePhotoUpdateResult result, {
    required String cleanupLabel,
  }) {
    final warnings = <String>[];
    if (result.previousPhotoCleanupFailed) warnings.add(cleanupLabel);
    if (result.profileCacheUpdateFailed) {
      warnings.add('The local profile cache could not be updated.');
    }
    return warnings.isEmpty ? success : '$success ${warnings.join(' ')}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      ProfileAvatar(
        name: _profile.fullName?.trim().isNotEmpty == true
            ? _profile.fullName!.trim()
            : _profile.email ?? 'Inventory User',
        avatarUrl: _profile.avatarUrl,
        size: widget.avatarSize,
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _isBusy ? null : _choosePhoto,
              icon: _isBusy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo_outlined),
              label: Text(_profile.avatarUrl == null ? 'Add photo' : 'Change'),
            ),
            if (_profile.avatarUrl != null)
              TextButton.icon(
                onPressed: _isBusy ? null : _removePhoto,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              ),
          ],
        ),
      ),
    ],
  );
}
