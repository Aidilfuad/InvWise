import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';

/// Two equal-width buttons: outlined "Add Stock" + filled "Adjust Stock".
class ItemActionButtons extends StatelessWidget {
  const ItemActionButtons({
    super.key,
    this.onAddStockTap,
    this.onAdjustStockTap,
  });

  final VoidCallback? onAddStockTap;
  final VoidCallback? onAdjustStockTap;

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onAddStockTap,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(_height),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              textStyle: labelStyle,
            ),
            child: const Text('Add Stock'),
          ),
        ),
        AppSpacing.gapMd,
        Expanded(
          child: FilledButton(
            onPressed: onAdjustStockTap,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(_height),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              textStyle: labelStyle,
            ),
            child: const Text('Adjust Stock'),
          ),
        ),
      ],
    );
  }
}