import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';

/// UI models + dummy data for the Reports screen.
/// Replace with real models / repositories when the backend is connected.

enum TrendDirection {
  up(Icons.arrow_upward_rounded),
  down(Icons.arrow_downward_rounded),
  flat(Icons.remove_rounded);

  const TrendDirection(this.icon);

  final IconData icon;
}

/// Whether a change is good, bad or neutral for the business
/// (e.g. more low-stock items is *negative* even though the arrow points up).
enum TrendTone {
  positive(AppColors.successContainer, AppColors.onSuccessContainer),
  negative(AppColors.dangerContainer, AppColors.onDangerContainer),
  neutral(AppColors.surfaceVariant, AppColors.textSecondary);

  const TrendTone(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

class TrendDelta {
  const TrendDelta({
    required this.label,
    required this.direction,
    required this.tone,
  });

  final String label;
  final TrendDirection direction;
  final TrendTone tone;
}

class ReportKpi {
  const ReportKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.delta,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final TrendDelta delta;
}

class TurnoverTrend {
  const TurnoverTrend({
    required this.months,
    required this.values,
    required this.target,
    required this.axisMin,
    required this.axisMax,
    required this.delta,
  });

  final List<String> months;
  final List<double> values;
  final double target;
  final double axisMin;
  final double axisMax;
  final TrendDelta delta;

  double get current => values.last;
  String get currentLabel => '${current.toStringAsFixed(1)}x';
  String get targetLabel => 'Target ${target.toStringAsFixed(1)}x';
}

class TopMovingItem {
  const TopMovingItem({
    required this.name,
    required this.sku,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.changePercent,
  });

  final String name;
  final String sku;
  final String category;
  final int quantity;
  final String unit;
  final double changePercent;

  String get quantityLabel {
    final grouped = quantity.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
    return '$grouped $unit';
  }

  String get changeLabel =>
      '${changePercent > 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%';

  IconData get trendIcon => changePercent > 0
      ? Icons.trending_up_rounded
      : changePercent < 0
          ? Icons.trending_down_rounded
          : Icons.trending_flat_rounded;

  TrendTone get tone => changePercent > 0
      ? TrendTone.positive
      : changePercent < 0
          ? TrendTone.negative
          : TrendTone.neutral;
}

enum ActivityKind {
  received(
    icon: Icons.add_circle_rounded,
    iconColor: AppColors.success,
    background: AppColors.successContainer,
    valueColor: AppColors.onSuccessContainer,
  ),
  issued(
    icon: Icons.remove_circle_rounded,
    iconColor: AppColors.danger,
    background: AppColors.dangerContainer,
    valueColor: AppColors.onDangerContainer,
  ),
  transferred(
    icon: Icons.swap_horiz_rounded,
    iconColor: AppColors.primary,
    background: AppColors.primaryContainer,
    valueColor: AppColors.onPrimaryContainer,
  ),
  adjusted(
    icon: Icons.edit_note_rounded,
    iconColor: AppColors.warning,
    background: AppColors.warningContainer,
    valueColor: AppColors.onWarningContainer,
  );

  const ActivityKind({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final Color valueColor;
}

class InventoryActivity {
  const InventoryActivity({
    required this.kind,
    required this.description,
    required this.quantityChange,
    required this.timestamp,
  });

  final ActivityKind kind;
  final String description;
  final int quantityChange;
  final String timestamp;

  String get quantityLabel =>
      quantityChange > 0 ? '+$quantityChange' : '$quantityChange';
}

abstract final class ReportsMockData {
  static const String warehouseName = 'Industrial Warehouse A';
  static const String periodLabel = 'Jan – Jul';

  static const List<ReportKpi> kpis = [
    ReportKpi(
      label: 'Total Inventory Value',
      value: '\$1.28M',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: AppColors.primary,
      iconBackground: AppColors.primaryContainer,
      delta: TrendDelta(
        label: '4.2% vs Jun',
        direction: TrendDirection.up,
        tone: TrendTone.positive,
      ),
    ),
    ReportKpi(
      label: 'Low Stock Items',
      value: '14',
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.danger,
      iconBackground: AppColors.dangerContainer,
      delta: TrendDelta(
        label: '3 vs Jun',
        direction: TrendDirection.up,
        tone: TrendTone.negative,
      ),
    ),
    ReportKpi(
      label: 'Active Reservations',
      value: '37',
      icon: Icons.bookmark_added_rounded,
      iconColor: AppColors.info,
      iconBackground: AppColors.secondaryContainer,
      delta: TrendDelta(
        label: '5 pending pick',
        direction: TrendDirection.flat,
        tone: TrendTone.neutral,
      ),
    ),
    ReportKpi(
      label: 'Stock Adjustments This Month',
      value: '128',
      icon: Icons.tune_rounded,
      iconColor: AppColors.warning,
      iconBackground: AppColors.warningContainer,
      delta: TrendDelta(
        label: '8% vs Jun',
        direction: TrendDirection.down,
        tone: TrendTone.positive,
      ),
    ),
  ];

  static const TurnoverTrend turnover = TurnoverTrend(
    months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
    values: [3.2, 3.6, 3.4, 4.1, 4.3, 4.2, 4.6],
    target: 4.0,
    axisMin: 2,
    axisMax: 5,
    delta: TrendDelta(
      label: '0.4 vs Jun',
      direction: TrendDirection.up,
      tone: TrendTone.positive,
    ),
  );

  static const List<TopMovingItem> topMovingItems = [
    TopMovingItem(
      name: 'Steel Bearing 40mm',
      sku: 'SKU-8829',
      category: 'Bearings',
      quantity: 1240,
      unit: 'pcs',
      changePercent: 12.4,
    ),
    TopMovingItem(
      name: 'Copper Wiring 100m',
      sku: 'SKU-9920',
      category: 'Electrical',
      quantity: 980,
      unit: 'rolls',
      changePercent: 8.1,
    ),
    TopMovingItem(
      name: 'Hydraulic Pump G-2',
      sku: 'SKU-1042',
      category: 'Hydraulics',
      quantity: 312,
      unit: 'units',
      changePercent: -3.2,
    ),
    TopMovingItem(
      name: 'Industrial Drill Bit Set',
      sku: 'SKU-4491',
      category: 'Tooling',
      quantity: 265,
      unit: 'sets',
      changePercent: -5.6,
    ),
    TopMovingItem(
      name: 'Controller Module X4',
      sku: 'SKU-7310',
      category: 'Electronics',
      quantity: 198,
      unit: 'units',
      changePercent: 15.3,
    ),
  ];

  static const List<InventoryActivity> recentActivity = [
    InventoryActivity(
      kind: ActivityKind.received,
      description: 'Steel Bearing received',
      quantityChange: 50,
      timestamp: '10 min ago',
    ),
    InventoryActivity(
      kind: ActivityKind.issued,
      description: 'Bearings issued',
      quantityChange: -12,
      timestamp: '45 min ago',
    ),
    InventoryActivity(
      kind: ActivityKind.received,
      description: 'Wiring received',
      quantityChange: 100,
      timestamp: '2 h ago',
    ),
    InventoryActivity(
      kind: ActivityKind.transferred,
      description: 'Pumps transferred',
      quantityChange: -5,
      timestamp: '5 h ago',
    ),
    InventoryActivity(
      kind: ActivityKind.adjusted,
      description: 'Drill Bit Set adjusted',
      quantityChange: -2,
      timestamp: 'Yesterday, 16:20',
    ),
  ];
}
