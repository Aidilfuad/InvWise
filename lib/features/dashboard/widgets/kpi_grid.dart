import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../data/dashboard_data.dart';

class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.stats, this.compact = false});

  final List<KpiStat> stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var index = 0; index < stats.length; index++)
            _CompactKpi(stat: stats[index], label: _compactLabel(index)),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200 ? 4 : 2;
        const gap = 12.0;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final stat in stats)
              SizedBox(
                width: cardWidth,
                child: _KpiCard(stat: stat),
              ),
          ],
        );
      },
    );
  }

  String _compactLabel(int index) => switch (index) {
    0 => 'Items',
    1 => 'Low',
    2 => 'OOS',
    3 => 'Sites',
    _ => stats[index].label,
  };
}

class _CompactKpi extends StatelessWidget {
  const _CompactKpi({required this.stat, required this.label});

  final KpiStat stat;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: stat.value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.stat});

  final KpiStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  stat.value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(stat.icon, size: 20, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: stat.captionColor),
          ),
        ],
      ),
    );
  }
}
