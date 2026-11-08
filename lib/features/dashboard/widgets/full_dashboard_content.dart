import 'package:flutter/material.dart';

import '../../../app/constants/app_spacing.dart';
import '../../../widgets/offline_sync_indicator.dart';
import '../data/dashboard_data.dart';
import 'attention_required_card.dart';
import 'dashboard_home_header.dart';
import 'dashboard_section_header.dart';
import 'inventory_health_card.dart';
import 'inventory_overview_card.dart';
import 'kpi_grid.dart';
import 'monthly_insights_card.dart';
import 'quick_actions_grid.dart';
import 'recent_activity_card.dart';
import 'recent_system_activity_card.dart';
import 'sensor_monitoring_card.dart';
import 'system_alerts_card.dart';
import 'system_health_summary_card.dart';

class FullDashboardContent extends StatelessWidget {
  const FullDashboardContent({
    super.key,
    required this.data,
    required this.greeting,
    required this.name,
    required this.role,
    required this.initials,
    required this.visibleActions,
    required this.activityPermission,
    required this.onNotificationsTap,
    required this.onProfileTap,
    required this.onActivityTap,
    required this.onQuickActionTap,
    this.sensorMonitoring,
    this.systemAlerts,
  });

  final DashboardData data;
  final String greeting;
  final String name;
  final String role;
  final String initials;
  final List<QuickActionItem> visibleActions;
  final bool activityPermission;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;
  final VoidCallback onActivityTap;
  final ValueChanged<QuickActionItem> onQuickActionTap;
  final Widget? sensorMonitoring;
  final Widget? systemAlerts;

  @override
  Widget build(BuildContext context) {
    const sectionGap = AppSpacing.xl;
    const cardGap = AppSpacing.md;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OfflineSyncIndicator(),
        DashboardHomeHeader(
          greeting: greeting,
          name: name,
          role: role,
          initials: initials,
          onNotificationsTap: onNotificationsTap,
          onProfileTap: onProfileTap,
        ),
        const SizedBox(height: sectionGap),
        InventoryOverviewCard(summary: data, featured: true),
        const SizedBox(height: cardGap),
        KpiGrid(stats: data.kpis),
        const SizedBox(height: sectionGap),
        DashboardSectionHeader(
          title: 'Attention Required',
          actionLabel: 'View Alerts',
          onActionTap: onNotificationsTap,
        ),
        const SizedBox(height: cardGap),
        AttentionRequiredCard(items: data.attentionItems),
        const SizedBox(height: sectionGap),
        DashboardSectionHeader(
          title: 'Recent Activity',
          actionLabel: activityPermission ? 'View All' : null,
          onActionTap: activityPermission ? onActivityTap : null,
        ),
        const SizedBox(height: cardGap),
        RecentSystemActivityCard(entries: data.systemActivities),
        const SizedBox(height: sectionGap),
        DashboardSectionHeader(title: 'Live Inventory Summary'),
        const SizedBox(height: cardGap),
        MonthlyInsightsCard(
          month: data.insightsMonth,
          range: 'Current totals',
          insights: data.insights,
        ),
        const SizedBox(height: sectionGap),
        sensorMonitoring ?? const SensorMonitoringCard(),
        const SizedBox(height: sectionGap),
        const SystemHealthSummaryCard(),
        const SizedBox(height: sectionGap),
        DashboardSectionHeader(title: 'Inventory Health'),
        const SizedBox(height: cardGap),
        InventoryHealthCard(summary: data.summary),
        const SizedBox(height: sectionGap),
        DashboardSectionHeader(title: 'System Alerts'),
        const SizedBox(height: cardGap),
        systemAlerts ?? const SystemAlertsCard(),
        const SizedBox(height: sectionGap),
        DashboardSectionHeader(
          title: 'Recent Stock Movements',
          actionLabel: activityPermission ? 'View All' : null,
          onActionTap: activityPermission ? onActivityTap : null,
        ),
        const SizedBox(height: cardGap),
        RecentActivityCard(
          dateLabel: 'LATEST MOVEMENTS',
          entries: data.recentMovements,
        ),
        if (visibleActions.isNotEmpty) ...[
          const SizedBox(height: sectionGap),
          DashboardSectionHeader(title: 'Quick Actions'),
          const SizedBox(height: cardGap),
          QuickActionsGrid(
            actions: visibleActions,
            onActionTap: onQuickActionTap,
          ),
        ],
      ],
    );
  }
}
