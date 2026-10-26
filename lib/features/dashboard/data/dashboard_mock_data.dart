import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';

/// UI models + dummy data for the dashboard.
/// Replace with real models / repositories when the backend is connected.

class InventoryOverview {
  const InventoryOverview({
    required this.totalItems,
    required this.inventoryValue,
    required this.healthyPercent,
    required this.healthyCount,
    required this.attentionCount,
  });

  final String totalItems;
  final String inventoryValue;
  final double healthyPercent;
  final int healthyCount;
  final int attentionCount;
}

class KpiStat {
  const KpiStat({
    required this.value,
    required this.label,
    required this.caption,
    required this.icon,
    required this.captionColor,
  });

  final String value;
  final String label;
  final String caption;
  final IconData icon;
  final Color captionColor;
}

class AttentionItem {
  const AttentionItem({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String title;
  final String subtitle;
  final String count;
  final IconData icon;
  final Color color;
  final Color background;
}

enum QuickActionType { addItem, inventory, reports, activityLog }

class QuickActionItem {
  const QuickActionItem({
    required this.type,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final QuickActionType type;
  final String label;
  final String subtitle;
  final IconData icon;
}

class ActivityEntry {
  const ActivityEntry({
    required this.typeLabel,
    required this.title,
    required this.meta,
    required this.detail,
    required this.detailColor,
    required this.time,
    required this.icon,
  });

  final String typeLabel;
  final String title;
  final String meta;
  final String detail;
  final Color detailColor;
  final String time;
  final IconData icon;
}

class InsightStat {
  const InsightStat({
    required this.label,
    required this.value,
    required this.delta,
    required this.progress,
  });

  final String label;
  final String value;
  final String delta;
  final double progress;
}

abstract final class DashboardMockData {
  // Header
  static const String greeting = 'Good Morning';
  static const String userName = 'Aidil Fuad';
  static const String userRole = 'Inventory Administrator';
  static const String userInitials = 'AF';

  // Inventory overview
  static const InventoryOverview overview = InventoryOverview(
    totalItems: '1,248',
    inventoryValue: 'RM 486,250',
    healthyPercent: 97.8,
    healthyCount: 1220,
    attentionCount: 28,
  );

  // KPI grid
  static const List<KpiStat> kpis = [
    KpiStat(
      value: '1,248',
      label: 'Total Items',
      caption: '+48 this month',
      icon: Icons.inventory_2_outlined,
      captionColor: AppColors.textSecondary,
    ),
    KpiStat(
      value: '28',
      label: 'Low Stock Items',
      caption: 'Includes 6 critical',
      icon: Icons.warning_amber_rounded,
      captionColor: AppColors.warning,
    ),
    KpiStat(
      value: '16',
      label: 'Categories',
      caption: 'Across all inventory',
      icon: Icons.layers_outlined,
      captionColor: AppColors.textSecondary,
    ),
    KpiStat(
      value: '4',
      label: 'Warehouse Locations',
      caption: 'All locations active',
      icon: Icons.warehouse_outlined,
      captionColor: AppColors.textSecondary,
    ),
  ];

  // Attention required
  static const List<AttentionItem> attentionItems = [
    AttentionItem(
      title: 'Low Stock',
      subtitle: 'Below reorder level',
      count: '28',
      icon: Icons.inventory_2_outlined,
      color: AppColors.warning,
      background: AppColors.warningContainer,
    ),
    AttentionItem(
      title: 'Critical Items',
      subtitle: '6 of 28 need urgent restocking',
      count: '6',
      icon: Icons.error_outline_rounded,
      color: AppColors.danger,
      background: AppColors.dangerContainer,
    ),
  ];

  // Quick actions
  static const List<QuickActionItem> quickActions = [
    QuickActionItem(
      type: QuickActionType.addItem,
      label: 'Add Item',
      subtitle: 'Register new stock',
      icon: Icons.add_rounded,
    ),
    QuickActionItem(
      type: QuickActionType.inventory,
      label: 'Inventory',
      subtitle: 'Browse all items',
      icon: Icons.inventory_2_outlined,
    ),
    QuickActionItem(
      type: QuickActionType.reports,
      label: 'Reports',
      subtitle: 'Explore your data',
      icon: Icons.bar_chart_rounded,
    ),
    QuickActionItem(
      type: QuickActionType.activityLog,
      label: 'Activity Log',
      subtitle: 'Track every change',
      icon: Icons.history_rounded,
    ),
  ];

  // Recent activity
  static const String activityDate = 'TODAY · 25 OCTOBER 2026';

  static const List<ActivityEntry> activities = [
    ActivityEntry(
      typeLabel: 'Added Item',
      title: 'SKF 6205 Bearing',
      meta: 'BRG-0625 · Shah Alam',
      detail: '+120 units',
      detailColor: AppColors.success,
      time: '9:24 AM',
      icon: Icons.inventory_2_outlined,
    ),
    ActivityEntry(
      typeLabel: 'Updated Item',
      title: 'Industrial Safety Helmet',
      meta: 'PPE-0142 · Klang',
      detail: 'Reorder level: 40 → 60',
      detailColor: AppColors.textSecondary,
      time: '9:08 AM',
      icon: Icons.edit_note_rounded,
    ),
    ActivityEntry(
      typeLabel: 'Stock Adjustment',
      title: 'M12 Hex Bolt',
      meta: 'FST-0018 · Shah Alam',
      detail: '−8 units · Cycle count',
      detailColor: AppColors.textSecondary,
      time: '8:42 AM',
      icon: Icons.tune_rounded,
    ),
  ];

  // Monthly insights
  static const String insightsMonth = 'October 2026';
  static const String insightsRange = 'Month to date';

  static const List<InsightStat> insights = [
    InsightStat(
      label: 'Items Added',
      value: '48',
      delta: '+12 vs Sep',
      progress: 0.45,
    ),
    InsightStat(
      label: 'Items Updated',
      value: '126',
      delta: '+18 vs Sep',
      progress: 0.85,
    ),
    InsightStat(
      label: 'Stock Adjustments',
      value: '32',
      delta: '−9 vs Sep',
      progress: 0.30,
    ),
  ];
}