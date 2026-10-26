import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../data/activity_log_mock_data.dart';

class ActivityFilterChips extends StatelessWidget {
  const ActivityFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ActivityFilter selected;
  final ValueChanged<ActivityFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = ActivityFilter.values;

    return Column(
      children: [
        _buildRow(context, filters.sublist(0, 3)),
        SizedBox(height: AppSpacing.sm),
        _buildRow(context, filters.sublist(3, 6)),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<ActivityFilter> items) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: AppSpacing.sm),
          Expanded(child: _chip(context, items[i])),
        ],
      ],
    );
  }

  Widget _chip(BuildContext context, ActivityFilter filter) {
    final textTheme = Theme.of(context).textTheme;
    final isSelected = filter == selected;

    return Material(
      color: isSelected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onSelected(filter),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                Icon(Icons.check, size: 16, color: Colors.white),
                SizedBox(width: 4),
              ],
              Text(
                filter.label,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}