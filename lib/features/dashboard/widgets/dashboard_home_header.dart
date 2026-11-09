import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../widgets/profile_avatar.dart';

class DashboardHomeHeader extends StatelessWidget {
  const DashboardHomeHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.role,
    required this.initials,
    this.avatarUrl,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  final String greeting;
  final String name;
  final String role;
  final String initials;
  final String? avatarUrl;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo/invwise_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'InvWise',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ProfileAvatar(
                  name: name,
                  avatarUrl: avatarUrl,
                  size: 48,
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onNotificationsTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                    Positioned(
                      top: 11,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
