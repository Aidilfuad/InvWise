import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:image/image.dart' as img;
import 'package:invwise/services/profile_photo_service.dart';
import 'package:invwise/services/profile_service.dart';
import 'package:invwise/services/user_management_service.dart';
import 'package:invwise/widgets/profile_avatar.dart';
import 'package:invwise/widgets/profile_photo_crop_screen.dart';
import 'package:invwise/widgets/profile_photo_editor.dart';

void main() {
  const profile = ProfileLookupResult(
    id: 'profile-id',
    authUserId: 'auth-user-id',
    fullName: 'Jane Doe',
    email: 'jane@example.com',
  );

  testWidgets('profile avatar falls back to initials when no photo exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProfileAvatar(name: 'Jane Doe')),
      ),
    );

    expect(find.text('JD'), findsOneWidget);
  });

  testWidgets('profile photo editor offers gallery selection', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePhotoEditor(profile: profile, onProfileUpdated: (_) {}),
        ),
      ),
    );

    expect(find.text('Add photo'), findsOneWidget);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    expect(find.text('Remove'), findsNothing);
  });

  test('profile photo URL is included in remote and cached profile data', () {
    const avatarUrl = 'auth-user-id/photo-id.jpg';
    final profile = ProfileLookupResult.fromMap({
      'id': 'profile-id',
      'auth_user_id': 'auth-user-id',
      'avatar_url': avatarUrl,
    });

    expect(profile.avatarUrl, avatarUrl);
    expect(
      ProfileLookupResult.fromCacheMap(profile.toCacheMap()).avatarUrl,
      avatarUrl,
    );
    expect(profile.copyWithAvatarUrl(null).avatarUrl, isNull);
  });

  test('crop output is encoded as a compressed 512 square JPEG', () {
    final png = Uint8List.fromList(
      img.encodePng(img.Image(width: 128, height: 128)),
    );
    final jpeg = ProfilePhotoService.encodeCroppedJpeg(png);
    final decoded = img.decodeImage(jpeg);

    expect(jpeg.take(3), [0xff, 0xd8, 0xff]);
    expect(decoded?.width, 512);
    expect(decoded?.height, 512);
    expect(ProfilePhotoService.isValidCroppedJpeg(jpeg), isTrue);
  });

  test('non-square crop output is rejected', () {
    final png = Uint8List.fromList(
      img.encodePng(img.Image(width: 128, height: 64)),
    );

    expect(
      () => ProfilePhotoService.encodeCroppedJpeg(png),
      throwsA(isA<ProfilePhotoServiceException>()),
    );
    expect(ProfilePhotoService.isValidCroppedJpeg(png), isFalse);
  });

  testWidgets('crop screen locks a circular 1:1 crop and allows interaction', (
    tester,
  ) async {
    final png = Uint8List.fromList(
      img.encodePng(img.Image(width: 64, height: 64)),
    );
    await tester.pumpWidget(
      MaterialApp(home: ProfilePhotoCropScreen(imageBytes: png)),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(crop.aspectRatio, 1);
    expect(crop.withCircleUi, isTrue);
    expect(crop.interactive, isTrue);
    expect(crop.fixCropRect, isTrue);
    expect(find.text('Use this photo'), findsOneWidget);
  });

  testWidgets('crop screen returns only the resized JPEG result', (
    tester,
  ) async {
    final png = Uint8List.fromList(
      img.encodePng(img.Image(width: 64, height: 64)),
    );
    Uint8List? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await ProfilePhotoCropScreen.open(
                  context,
                  imageBytes: png,
                );
              },
              child: const Text('Open crop'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open crop'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this photo'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(
      result,
      isNotNull,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((e) => e.data)
          .join(' | '),
    );
    expect(ProfilePhotoService.isValidCroppedJpeg(result!), isTrue);
  });

  test('original and uncompressed bytes are not valid upload data', () {
    expect(
      ProfilePhotoService.isValidCroppedJpeg(Uint8List.fromList([1, 2, 3])),
      isFalse,
    );
  });

  test('managed user maps avatar_url from the user-list response', () {
    final user = ManagedUser.fromMap({
      'id': 'profile-id',
      'auth_user_id': 'auth-user-id',
      'full_name': 'Jane Doe',
      'email': 'jane@example.com',
      'avatar_url': 'auth-user-id/photo-id.jpg',
      'role': 'Storekeeper',
      'is_active': true,
      'is_self': false,
    });

    expect(user.avatarUrl, 'auth-user-id/photo-id.jpg');
  });
}
