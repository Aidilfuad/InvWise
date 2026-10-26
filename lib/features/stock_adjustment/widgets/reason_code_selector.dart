import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../data/stock_adjustment_mock_data.dart';

/// Wrapping group of pill-shaped single-select chips with leading icons.
class ReasonCodeSelector extends StatelessWidget {
  const ReasonCodeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.reasons = ReasonCode.values,
  });

  final ReasonCode selected;
  final ValueChanged<ReasonCode> onChanged;
  final List<ReasonCode> reasons;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final reason in reasons)
          _ReasonPill(
            reason: reason,
            selected: reason == selected,
            onTap: () => onChanged(reason),
          ),
      ],
    );
  }
}

class _ReasonPill extends StatelessWidget {
  const _ReasonPill({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final ReasonCode reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground =
        selected ? AppColors.textOnPrimary : AppColors.textPrimary;

    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: StadiumBorder(
        side: selected
            ? BorderSide.none
            : const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(reason.icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                reason.label,
                style: textTheme.labelMedium?.copyWith(
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
