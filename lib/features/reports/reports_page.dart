import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import 'data/reports_mock_data.dart';
import 'widgets/export_report_actions.dart';
import 'widgets/inventory_turnover_chart.dart';
import 'widgets/recent_inventory_activity.dart';
import 'widgets/report_kpi_cards.dart';
import 'widgets/top_moving_items_card.dart';
import '../activity_log/activity_log_page.dart';

/// Reports screen: KPIs, one turnover chart, top movers, activity and export.
/// UI only, backed by dummy data.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  static const double _maxContentWidth = 600;
  static const double _sectionGap = 20;

  void _onBackTap(BuildContext context) {
    Navigator.of(context).maybePop();
  }

  void _onViewAllActivityTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ActivityLogPage(),
      ),
    );
  }

  void _onExportPdfTap() {
    // TODO: Export the current report as PDF.
  }

  void _onExportExcelTap() {
    // TODO: Export the current report as Excel.
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _onBackTap(context),
        ),
        title: Text(
          'Reports',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl - AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xl - AppSpacing.xs,
              AppSpacing.xxl + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ReportContext(),
                AppSpacing.gapMd,
                const ReportKpiCards(kpis: ReportsMockData.kpis),
                const SizedBox(height: _sectionGap),
                const InventoryTurnoverChart(trend: ReportsMockData.turnover),
                const SizedBox(height: _sectionGap),
                const TopMovingItemsCard(
                  items: ReportsMockData.topMovingItems,
                ),
                const SizedBox(height: _sectionGap),
                RecentInventoryActivity(
                  activities: ReportsMockData.recentActivity,
                  onViewAllTap: () => _onViewAllActivityTap(context),
                ),
                const SizedBox(height: _sectionGap),
                ExportReportActions(
                  onExportPdfTap: _onExportPdfTap,
                  onExportExcelTap: _onExportExcelTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One-line context under the app bar: warehouse and reporting period.
class _ReportContext extends StatelessWidget {
  const _ReportContext();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        const Icon(
          Icons.warehouse_rounded,
          size: 16,
          color: AppColors.primary,
        ),
        AppSpacing.gapSm,
        Flexible(
          child: Text(
            '${ReportsMockData.warehouseName} · ${ReportsMockData.periodLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
