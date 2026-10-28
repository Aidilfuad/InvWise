import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../services/activity_log_service.dart';

class ActivityLogCard extends StatelessWidget {
  const ActivityLogCard({super.key, required this.entry});

  final ActivityLogEntry entry;

  Color get _color => switch (entry.type) {
    ActivityEventType.inventoryCreated ||
    ActivityEventType.receipt ||
    ActivityEventType.returnItem => AppColors.success,
    ActivityEventType.inventoryDeleted ||
    ActivityEventType.issue => AppColors.danger,
    ActivityEventType.stockAdjustment => AppColors.warning,
    ActivityEventType.inventoryUpdated ||
    ActivityEventType.transfer => AppColors.primary,
  };

  IconData get _icon => switch (entry.type) {
    ActivityEventType.inventoryCreated => Icons.inventory_2_outlined,
    ActivityEventType.inventoryUpdated => Icons.edit_outlined,
    ActivityEventType.inventoryDeleted => Icons.delete_outline,
    ActivityEventType.stockAdjustment => Icons.tune_rounded,
    ActivityEventType.receipt => Icons.south_west,
    ActivityEventType.issue => Icons.north_east,
    ActivityEventType.returnItem => Icons.assignment_return_outlined,
    ActivityEventType.transfer => Icons.swap_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final quantity = entry.quantityLabel;
    final contextLabel = entry.context;

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
          Text(
            entry.title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (entry.sku.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'SKU · ${entry.sku}',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon, size: 16, color: _color),
                    const SizedBox(width: 6),
                    Text(
                      entry.type.label,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (quantity.isNotEmpty)
                Text(
                  quantity,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            entry.description,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (contextLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              contextLabel,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: AppColors.border),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(entry.occurredAt),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _formatTime(entry.occurredAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.person_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  entry.actorProfileId ?? 'System',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} '
      '${_month(date.month)} ${date.year}';

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} '
        '${date.hour < 12 ? 'AM' : 'PM'}';
  }

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}
