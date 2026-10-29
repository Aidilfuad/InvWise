import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../services/activity_log_service.dart';
import '../../../services/stock_movement_service.dart';

class DashboardInventorySummary {
  const DashboardInventorySummary({
    required this.totalItems,
    required this.totalStockQuantity,
    required this.lowStockItems,
    required this.outOfStockItems,
    required this.warehouseLocations,
  });

  final int totalItems;
  final double totalStockQuantity;
  final int lowStockItems;
  final int outOfStockItems;
  final int warehouseLocations;
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

class DashboardData {
  const DashboardData({
    required this.summary,
    required this.recentMovements,
    required this.recentActivity,
  });

  final DashboardInventorySummary summary;
  final List<StockMovement> recentMovements;
  final List<ActivityLogEntry> recentActivity;

  List<KpiStat> get kpis => [
    KpiStat(
      value: _formatInteger(summary.totalItems),
      label: 'Total Items',
      caption: 'Inventory records',
      icon: Icons.inventory_2_outlined,
      captionColor: AppColors.textSecondary,
    ),
    KpiStat(
      value: _formatInteger(summary.lowStockItems),
      label: 'Low Stock Items',
      caption: 'At or below minimum stock',
      icon: Icons.warning_amber_rounded,
      captionColor: AppColors.warning,
    ),
    KpiStat(
      value: _formatInteger(summary.outOfStockItems),
      label: 'Out of Stock',
      caption: 'No stock available',
      icon: Icons.remove_shopping_cart_outlined,
      captionColor: AppColors.danger,
    ),
    KpiStat(
      value: _formatInteger(summary.warehouseLocations),
      label: 'Warehouse Locations',
      caption: 'Registered locations',
      icon: Icons.warehouse_outlined,
      captionColor: AppColors.textSecondary,
    ),
  ];

  List<AttentionItem> get attentionItems => [
    AttentionItem(
      title: 'Low Stock',
      subtitle: 'At or below minimum stock',
      count: _formatInteger(summary.lowStockItems),
      icon: Icons.inventory_2_outlined,
      color: AppColors.warning,
      background: AppColors.warningContainer,
    ),
    AttentionItem(
      title: 'Out of Stock',
      subtitle: 'Items with no available stock',
      count: _formatInteger(summary.outOfStockItems),
      icon: Icons.error_outline_rounded,
      color: AppColors.danger,
      background: AppColors.dangerContainer,
    ),
  ];

  String get totalItemsLabel => _formatInteger(summary.totalItems);
  String get totalStockQuantityLabel =>
      _formatQuantity(summary.totalStockQuantity);
  double get healthyPercent {
    if (summary.totalItems == 0) return 0;
    final healthy = healthyCount;
    return (healthy / summary.totalItems * 100).clamp(0, 100).toDouble();
  }

  int get healthyCount =>
      (summary.totalItems - summary.lowStockItems - summary.outOfStockItems)
          .clamp(0, summary.totalItems);
  int get attentionCount => (summary.lowStockItems + summary.outOfStockItems)
      .clamp(0, summary.totalItems);

  String get insightsMonth {
    final now = DateTime.now();
    return '${_monthName(now.month)} ${now.year}';
  }

  List<InsightStat> get insights => [
    InsightStat(
      label: 'Total Stock Quantity',
      value: totalStockQuantityLabel,
      delta: 'Current balance',
      progress: 1,
    ),
    InsightStat(
      label: 'Low Stock Items',
      value: _formatInteger(summary.lowStockItems),
      delta: 'Current count',
      progress: summary.totalItems == 0
          ? 0
          : (summary.lowStockItems / summary.totalItems).clamp(0, 1),
    ),
    InsightStat(
      label: 'Out of Stock Items',
      value: _formatInteger(summary.outOfStockItems),
      delta: 'Current count',
      progress: summary.totalItems == 0
          ? 0
          : (summary.outOfStockItems / summary.totalItems).clamp(0, 1),
    ),
  ];

  String get activityDate {
    if (recentActivity.isEmpty) return 'RECENT STOCK MOVEMENTS';
    final date = recentActivity.first.occurredAt.toLocal();
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return 'RECENT ACTIVITY · ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}

const dashboardQuickActions = [
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
    label: 'Stock Movements',
    subtitle: 'Track stock movement',
    icon: Icons.history_rounded,
  ),
];

String _formatInteger(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

String _formatQuantity(double value) =>
    value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
