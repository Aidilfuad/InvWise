import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../activity_log/activity_log_page.dart';
import '../alerts_page/alerts_page.dart';
import '../inventory/inventory_page.dart';
import '../inventory_item/inventory_item_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';
import 'data/dashboard_mock_data.dart';
import 'widgets/attention_required_card.dart';
import 'widgets/dashboard_home_header.dart';
import 'widgets/dashboard_section_header.dart';
import 'widgets/inventory_overview_card.dart';
import 'widgets/kpi_grid.dart';
import 'widgets/monthly_insights_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/recent_activity_card.dart';

/// Dashboard screen. UI only, backed by dummy data.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const double _maxContentWidth = 600;

  void _onNotificationsTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AlertsPage()),
    );
  }

  void _onProfileTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
    );
  }

  void _onViewAlertsTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AlertsPage()),
    );
  }

  void _onQuickActionTap(BuildContext context, QuickActionItem action) {
    switch (action.type) {
      case QuickActionType.addItem:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const InventoryItemPage()),
        );
        break;
      case QuickActionType.inventory:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const InventoryPage()),
        );
        break;
      case QuickActionType.reports:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ReportsPage()),
        );
        break;
      case QuickActionType.activityLog:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ActivityLogPage()),
        );
        break;
    }
  }

  void _onViewAllActivityTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ActivityLogPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DashboardHomeHeader(
                      greeting: DashboardMockData.greeting,
                      name: DashboardMockData.userName,
                      role: DashboardMockData.userRole,
                      initials: DashboardMockData.userInitials,
                      onNotificationsTap: () => _onNotificationsTap(context),
                      onProfileTap: () => _onProfileTap(context),
                    ),
                    AppSpacing.gapXl,
                    const InventoryOverviewCard(
                      overview: DashboardMockData.overview,
                    ),
                    AppSpacing.gapLg,
                    const KpiGrid(stats: DashboardMockData.kpis),
                    AppSpacing.gapXl,
                    DashboardSectionHeader(
                      title: 'Attention Required',
                      actionLabel: 'View Alerts',
                      onActionTap: () => _onViewAlertsTap(context),
                    ),
                    AppSpacing.gapMd,
                    AttentionRequiredCard(
                      items: DashboardMockData.attentionItems,
                    ),
                    AppSpacing.gapXl,
                    const DashboardSectionHeader(title: 'Quick Actions'),
                    AppSpacing.gapMd,
                    QuickActionsGrid(
                      actions: DashboardMockData.quickActions,
                      onActionTap: (action) =>
                          _onQuickActionTap(context, action),
                    ),
                    AppSpacing.gapXl,
                    DashboardSectionHeader(
                      title: 'Recent Activity',
                      actionLabel: 'View All',
                      onActionTap: () => _onViewAllActivityTap(context),
                    ),
                    AppSpacing.gapMd,
                    const RecentActivityCard(
                      dateLabel: DashboardMockData.activityDate,
                      entries: DashboardMockData.activities,
                    ),
                    AppSpacing.gapXl,
                    const DashboardSectionHeader(title: 'Monthly Insights'),
                    AppSpacing.gapMd,
                    const MonthlyInsightsCard(
                      month: DashboardMockData.insightsMonth,
                      range: DashboardMockData.insightsRange,
                      insights: DashboardMockData.insights,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}