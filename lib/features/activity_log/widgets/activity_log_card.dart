import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../data/activity_log_mock_data.dart';

class ActivityLogCard extends StatelessWidget {
  const ActivityLogCard({super.key, required this.entry});

  final ActivityLogEntry entry;

  static const Color _greenFg = Color(0xFF15803D);
  static const Color _greenBg = Color(0xFFE8F6EE);
  static const Color _redFg = Color(0xFFC2410C);
  static const Color _redBg = Color(0xFFFDEDE7);
  static const Color _blueBg = Color(0xFFEAF0FE);

  String get _label {
    switch (entry.type) {
      case ActivityType.addItem:
        return 'Add Item';
      case ActivityType.editItem:
        return 'Edit Item';
      case ActivityType.stockIn:
        return 'Stock In';
      case ActivityType.stockOut:
        return 'Stock Out';
      case ActivityType.audit:
        return 'Audit';
    }
  }

  IconData get _icon {
    switch (entry.type) {
      case ActivityType.addItem:
        return Icons.inventory_2_outlined;
      case ActivityType.editItem:
        return Icons.edit_outlined;
      case ActivityType.stockIn:
        return Icons.south_west;
      case ActivityType.stockOut:
        return Icons.north_east;
      case ActivityType.audit:
        return Icons.assignment_turned_in_outlined;
    }
  }

  Color get _badgeFg {
    switch (entry.type) {
      case ActivityType.stockIn:
        return _greenFg;
      case ActivityType.stockOut:
        return _redFg;
      default:
        return AppColors.primary;
    }
  }

  Color get _badgeBg {
    switch (entry.type) {
      case ActivityType.stockIn:
        return _greenBg;
      case ActivityType.stockOut:
        return _redBg;
      default:
        return _blueBg;
    }
  }

  String get _quantityText {
    final q = entry.quantityChange;
    if (q > 0) return '+$q Units';
    if (q < 0) return '\u2212${q.abs()} Units';
    return '0 Units';
  }

  Color get _quantityColor {
    final q = entry.quantityChange;
    if (q > 0) return _greenFg;
    if (q < 0) return _redFg;
    return AppColors.textPrimary;
  }

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
          Text(
            entry.itemName,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'SKU · ${entry.sku}',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon, size: 16, color: _badgeFg),
                    SizedBox(width: 6),
                    Text(
                      _label,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _badgeFg,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Quantity change',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _quantityText,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _quantityColor,
                    ),
                  ),
                ],
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
          SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: AppColors.border),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.date,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    entry.time,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Icon(
                Icons.person_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                entry.user,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}