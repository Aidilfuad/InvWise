import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../services/profile_service.dart';
import '../../../widgets/profile_avatar.dart';
import '../../../widgets/profile_photo_editor.dart';

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  final ProfileLookupResult profile;
  final ValueChanged<ProfileLookupResult> onProfileUpdated;

  String get _displayName => profile.fullName?.trim().isNotEmpty == true
      ? profile.fullName!.trim()
      : profile.email ?? 'Inventory User';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ProfileAvatar(
                name: _displayName,
                avatarUrl: profile.avatarUrl,
                size: 64,
                backgroundColor: const Color(0xFFEAF0FE),
                foregroundColor: AppColors.primary,
                fontSize: textTheme.titleLarge?.fontSize,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      profile.role ?? 'User',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Employee ID',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF0FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            profile.employeeId ?? '—',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          ProfilePhotoEditor(
            profile: profile,
            onProfileUpdated: onProfileUpdated,
            avatarSize: 40,
          ),
        ],
      ),
    );
  }
}
