import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../data/reports_mock_data.dart';
import 'report_card.dart';
import 'trend_pill.dart';

/// Compact 2 x 2 grid of KPI cards.
///
/// Built from Rows (not GridView) so cards keep their natural height and
/// there is no fixed aspect ratio to break on different font scales.
class ReportKpiCards extends StatelessWidget {
  const ReportKpiCards({super.key, required this.kpis});

  final List<ReportKpi> kpis;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var i = 0; i < kpis.length; i += 2) {
      if (rows.isNotEmpty) rows.add(AppSpacing.gapMd);

      final hasSecond = i + 1 < kpis.length;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _KpiCard(kpi: kpis[i])),
            AppSpacing.gapMd,
            Expanded(
              child: hasSecond
                  ? _KpiCard(kpi: kpis[i + 1])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return Column(children: rows);
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});

  final ReportKpi kpi;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ReportCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: kpi.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(kpi.icon, size: 18, color: kpi.iconColor),
              ),
              AppSpacing.gapSm,
              // Scales the pill down instead of overflowing on narrow cards.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: TrendPill(delta: kpi.delta),
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              kpi.value,
              maxLines: 1,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          AppSpacing.gapXs,
          Text(
            kpi.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
