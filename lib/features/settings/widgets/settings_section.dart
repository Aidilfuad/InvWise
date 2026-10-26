import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';

/// Section label followed by a bordered group card. Dividers are inserted
/// between the children automatically (inset to start under the icon).
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  /// Dividers start under the icon box, as in the design.
  static const double _dividerIndent = 58;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            color: const Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.gapMd,
        Material(
          color: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusLg,
            side: BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(indent: _dividerIndent),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
