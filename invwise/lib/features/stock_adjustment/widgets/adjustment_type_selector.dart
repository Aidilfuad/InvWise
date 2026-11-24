import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../data/stock_adjustment_options.dart';

/// Two large selectable tiles: Add Stock / Remove Stock.
/// The selected tile is filled with the primary color.
class AdjustmentTypeSelector extends StatelessWidget {
  const AdjustmentTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AdjustmentType selected;
  final ValueChanged<AdjustmentType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < AdjustmentType.values.length; i++) ...[
          if (i > 0) AppSpacing.gapLg,
          Expanded(
            child: _TypeTile(
              type: AdjustmentType.values[i],
              selected: AdjustmentType.values[i] == selected,
              onTap: () => onChanged(AdjustmentType.values[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final AdjustmentType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = selected
        ? AppColors.textOnPrimary
        : AppColors.textPrimary;

    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        side: selected
            ? BorderSide.none
            : BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type.icon,
                size: 28,
                color: selected ? AppColors.textOnPrimary : AppColors.primary,
              ),
              AppSpacing.gapSm,
              Text(
                type.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
