import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../data/dashboard_mock_data.dart';

class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.stats});

  final List<KpiStat> stats;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < stats.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      final hasSecond = i + 1 < stats.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _KpiCard(stat: stats[i])),
              const SizedBox(width: 12),
              Expanded(
                child: hasSecond
                    ? _KpiCard(stat: stats[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.stat});

  final KpiStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                    fontSize: 26,
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
            style: TextStyle(
              fontSize: 11,
              color: stat.captionColor,
            ),
          ),
        ],
      ),
    );
  }
}