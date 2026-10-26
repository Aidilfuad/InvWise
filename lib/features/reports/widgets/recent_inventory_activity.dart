import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../data/reports_mock_data.dart';
import 'report_card.dart';
import 'report_section_header.dart';

/// "Recent Inventory Activity": icon, short description, timestamp and the
/// signed quantity for each stock movement.
class RecentInventoryActivity extends StatelessWidget {
  const RecentInventoryActivity({
    super.key,
    required this.activities,
    this.onViewAllTap,
  });

  final List<InventoryActivity> activities;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportSectionHeader(
          title: 'Recent Inventory Activity',
          actionLabel: 'View All',
          onActionTap: onViewAllTap,
        ),
        AppSpacing.gapMd,
        ReportCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: [
              for (var i = 0; i < activities.length; i++) ...[
                if (i > 0) const Divider(),
                _ActivityRow(activity: activities[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final InventoryActivity activity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final kind = activity.kind;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kind.background,
              shape: BoxShape.circle,
            ),
            child: Icon(kind.icon, size: 18, color: kind.iconColor),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.timestamp,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapMd,
          Text(
            activity.quantityLabel,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: kind.valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
