import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../data/reports_mock_data.dart';
import 'report_card.dart';
import 'report_section_header.dart';

/// "Top Moving Items": ranked list with movement quantity, a relative
/// movement bar and a trend indicator. Replaces a second chart.
class TopMovingItemsCard extends StatelessWidget {
  const TopMovingItemsCard({
    super.key,
    required this.items,
    this.periodLabel = 'Last 30 days',
  });

  final List<TopMovingItem> items;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final maxQuantity =
        items.isEmpty ? 1 : items.map((e) => e.quantity).reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportSectionHeader(title: 'Top Moving Items', subtitle: periodLabel),
        AppSpacing.gapMd,
        ReportCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(),
                _ItemRow(
                  rank: i + 1,
                  item: items[i],
                  relativeMovement: items[i].quantity / maxQuantity,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.rank,
    required this.item,
    required this.relativeMovement,
  });

  final int rank;
  final TopMovingItem item;
  final double relativeMovement;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.sku} · ${item.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AppSpacing.gapSm,
                LinearProgressIndicator(
                  value: relativeMovement,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceVariant,
                ),
              ],
            ),
          ),
          AppSpacing.gapLg,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.quantityLabel,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.trendIcon,
                    size: 14,
                    color: item.tone.foreground,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    item.changeLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: item.tone.foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rank 1 is solid blue, 2-3 are tinted, the rest are neutral.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (rank == 1) {
      background = AppColors.primary;
      foreground = AppColors.textOnPrimary;
    } else if (rank <= 3) {
      background = AppColors.primaryContainer;
      foreground = AppColors.onPrimaryContainer;
    } else {
      background = AppColors.surfaceVariant;
      foreground = AppColors.textSecondary;
    }

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        '$rank',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
