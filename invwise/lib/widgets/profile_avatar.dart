import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_photo_service.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 48,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
  });

  final String name;
  final String? avatarUrl;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.firstOrNull?.substring(0, 1).toUpperCase() ?? '?';
  }

  String? _imageUrl() {
    final value = avatarUrl?.trim();
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri?.hasScheme == true) return value;
    return Supabase.instance.client.storage
        .from(ProfilePhotoService.bucketName)
        .getPublicUrl(value);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl();
    return Semantics(
      image: true,
      label: '$name profile photo',
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: imageUrl == null
              ? _fallback()
              : Image.network(
                  imageUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallback(),
                ),
        ),
      ),
    );
  }

  Widget _fallback() => ColoredBox(
    color: backgroundColor ?? const Color(0xFFEAF0FE),
    child: Center(
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: fontSize ?? size * 0.3,
          fontWeight: FontWeight.w700,
          color: foregroundColor ?? const Color(0xFF2457C5),
        ),
      ),
    ),
  );
}
