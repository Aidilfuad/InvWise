import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';

class InventoryItemHeader extends StatelessWidget {
  const InventoryItemHeader({
    super.key,
    required this.title,
    required this.onBack,
    required this.onSave,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onSave;

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
            color: AppColors.primary.withOpacity(0.08),
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
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onSave,
            icon: Icon(Icons.save_outlined, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}