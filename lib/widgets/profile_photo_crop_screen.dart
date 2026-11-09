import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../app/constants/app_colors.dart';
import '../services/profile_photo_service.dart';

class ProfilePhotoCropScreen extends StatefulWidget {
  const ProfilePhotoCropScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  static Future<Uint8List?> open(
    BuildContext context, {
    required Uint8List imageBytes,
  }) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => ProfilePhotoCropScreen(imageBytes: imageBytes),
      ),
    );
  }

  @override
  State<ProfilePhotoCropScreen> createState() => _ProfilePhotoCropScreenState();
}

class _ProfilePhotoCropScreenState extends State<ProfilePhotoCropScreen> {
  final CropController _controller = CropController();
  bool _isReady = false;
  bool _isCropping = false;

  void _crop() {
    if (!_isReady || _isCropping) return;
    setState(() => _isCropping = true);
    _controller.crop();
  }

  void _onCropped(CropResult result) {
    switch (result) {
      case CropSuccess(:final croppedImage):
        try {
          Navigator.of(context)
              .pop(ProfilePhotoService.encodeCroppedJpeg(croppedImage));
        } catch (error) {
          setState(() => _isCropping = false);
          _showError('Unable to prepare the cropped photo: $error');
        }
      case CropFailure(:final cause):
        setState(() => _isCropping = false);
        _showError('Unable to crop the photo: $cause');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Crop profile photo'),
      leading: IconButton(
        tooltip: 'Cancel crop',
        onPressed: _isCropping ? null : () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Drag to reposition and pinch or scroll to zoom. '
              'Your avatar will be cropped to a square.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                    maxHeight: 520,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Crop(
                      image: widget.imageBytes,
                      controller: _controller,
                      aspectRatio: 1,
                      withCircleUi: true,
                      interactive: true,
                      fixCropRect: true,
                      initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                        size: 0.8,
                        aspectRatio: 1,
                      ),
                      baseColor: AppColors.textPrimary,
                      maskColor: Colors.black54,
                      onStatusChanged: (status) {
                        if (status == CropStatus.ready && mounted) {
                          setState(() => _isReady = true);
                        }
                      },
                      onCropped: _onCropped,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isReady && !_isCropping ? _crop : null,
                icon: _isCropping
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.crop),
                label: Text(
                  _isCropping ? 'Preparing photo…' : 'Use this photo',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
