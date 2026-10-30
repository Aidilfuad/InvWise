import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';

/// White title bar: large "Settings" title and a close button.
/// Extends under the status bar by adding the top safe-area inset itself.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key, this.onCloseTap});

  final VoidCallback? onCloseTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        topInset + 20,
        AppSpacing.md,
        20,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Settings',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: onCloseTap,
          ),
        ],
      ),
    );
  }
}
