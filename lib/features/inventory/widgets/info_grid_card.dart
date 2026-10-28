import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../data/item_details_data.dart';

/// Full-width white band with a 2-column grid of icon + label + value cells.
///
/// Built from Rows (not GridView) so a value that wraps onto two lines, like
/// "North Wing - Aisle 4", simply makes its row taller.
class InfoGridCard extends StatelessWidget {
  const InfoGridCard({super.key, required this.entries});

  final List<InfoEntry> entries;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var i = 0; i < entries.length; i += 2) {
      if (rows.isNotEmpty) rows.add(AppSpacing.gapXl);

      final hasSecond = i + 1 < entries.length;
      rows.add(
        Row(
          children: [
            Expanded(child: _InfoCell(entry: entries[i])),
            AppSpacing.gapMd,
            Expanded(
              child: hasSecond
                  ? _InfoCell(entry: entries[i + 1])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(children: rows),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.entry});

  final InfoEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.border,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Icon(entry.icon, size: 20, color: AppColors.primary),
        ),
        AppSpacing.gapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.label,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapXs,
              Text(
                entry.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
