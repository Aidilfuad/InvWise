import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';

enum ActivityType {
  received(
    icon: Icons.add_circle_rounded,
    color: AppColors.success,
    background: AppColors.successContainer,
  ),
  fulfilled(
    icon: Icons.remove_circle_rounded,
    color: AppColors.danger,
    background: AppColors.dangerContainer,
  ),
  adjustment(
    icon: Icons.edit_note_rounded,
    color: AppColors.warning,
    background: AppColors.warningContainer,
  );

  const ActivityType({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  Color get amountColor => switch (this) {
    ActivityType.received => AppColors.success,
    ActivityType.fulfilled => AppColors.danger,
    ActivityType.adjustment => AppColors.textPrimary,
  };
}

class ActivityEntry {
  const ActivityEntry({
    required this.title,
    required this.date,
    required this.actor,
    required this.amount,
    required this.type,
  });

  final String title;
  final String date;
  final String actor;
  final int amount;
  final ActivityType type;

  String get subtitle => '$date • $actor';
  String get amountLabel => amount > 0 ? '+$amount' : '$amount';
}

class InfoEntry {
  const InfoEntry({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class ItemDetails {
  const ItemDetails({
    required this.sku,
    required this.name,
    required this.currentStock,
    required this.unit,
    required this.unitPrice,
    required this.warehouse,
    required this.binLocation,
    required this.category,
    required this.minThreshold,
    this.activities = const [],
  });

  final String sku;
  final String name;
  final double currentStock;
  final String unit;
  final double unitPrice;
  final String warehouse;
  final String binLocation;
  final String category;
  final double minThreshold;
  final List<ActivityEntry> activities;

  String get currentStockLabel {
    final value = currentStock
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return value.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }

  String get unitPriceLabel => '\$${unitPrice.toStringAsFixed(2)}';

  String get minThresholdLabel => minThreshold
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'\.?0+$'), '')
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  List<InfoEntry> get infoEntries => [
    InfoEntry(
      icon: Icons.inventory_2_rounded,
      label: 'Warehouse',
      value: warehouse,
    ),
    InfoEntry(
      icon: Icons.location_on_rounded,
      label: 'Bin Location',
      value: binLocation,
    ),
    InfoEntry(
      icon: Icons.precision_manufacturing_rounded,
      label: 'Category',
      value: category,
    ),
    InfoEntry(
      icon: Icons.warning_amber_rounded,
      label: 'Min. Threshold',
      value: '${_formatQuantity(minThreshold)} $unit',
    ),
  ];

  static String _formatQuantity(double value) =>
      value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
}
