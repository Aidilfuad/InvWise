import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';

class ActivityLogHeader extends StatelessWidget {
  const ActivityLogHeader({
    super.key,
    required this.onBack,
    required this.onFilter,
  });

  final VoidCallback onBack;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFEAF0FE),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onBack,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.arrow_back, color: AppColors.primary),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Stock Movements',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onFilter,
            icon: Icon(Icons.tune, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
