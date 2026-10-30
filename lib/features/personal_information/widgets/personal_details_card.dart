import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../services/profile_service.dart';

/// Shared card shell used by all information cards on this page.
class InformationCardShell extends StatelessWidget {
  const InformationCardShell({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

/// One label / value row. Shows a divider above itself unless [isFirst].
class InformationRow extends StatelessWidget {
  const InformationRow({
    super.key,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.valueColor,
    this.showDot = false,
  });

  final String label;
  final String value;
  final bool isFirst;
  final Color? valueColor;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = valueColor ?? AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFirst) ...[
          Divider(height: 1, color: AppColors.border),
          SizedBox(height: AppSpacing.sm),
        ],
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: 2),
        Row(
          children: [
            if (showDot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class PersonalDetailsCard extends StatelessWidget {
  const PersonalDetailsCard({super.key, required this.profile});

  final ProfileLookupResult profile;

  @override
  Widget build(BuildContext context) {
    return InformationCardShell(
      icon: Icons.person_outline,
      title: 'Personal Details',
      children: [
        InformationRow(
          label: 'Full Name',
          value: profile.fullName ?? '—',
          isFirst: true,
        ),
        InformationRow(label: 'Email', value: profile.email ?? '—'),
        InformationRow(
          label: 'Phone Number',
          value: profile.phoneNumber ?? '—',
        ),
        InformationRow(label: 'Employee ID', value: profile.employeeId ?? '—'),
        InformationRow(label: 'Role', value: profile.role ?? '—'),
      ],
    );
  }
}
