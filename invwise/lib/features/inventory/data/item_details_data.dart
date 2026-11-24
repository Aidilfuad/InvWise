import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../services/currency_service.dart';

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
    required this.amountLabel,
    required this.type,
  });

  final String title;
  final String date;
  final String actor;
  final String amountLabel;
  final ActivityType type;

  String get subtitle => '$date • $actor';
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
    required this.inventoryValue,
    required this.warehouse,
    required this.category,
    required this.minThreshold,
    required this.description,
    required this.notes,
    this.activities = const [],
  });

  final String sku;
  final String name;
  final double currentStock;
  final String unit;
  final double unitPrice;
  final double inventoryValue;
  final String warehouse;
  final String category;
  final double minThreshold;
  final String description;
  final String notes;
  final List<ActivityEntry> activities;

  String get currentStockLabel {
    final value = currentStock
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return value.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }

  String get unitPriceLabel => CurrencyService.instance.formatMyr(unitPrice);
  String get inventoryValueLabel =>
      CurrencyService.instance.formatMyr(inventoryValue);

  String get minThresholdLabel => minThreshold
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'\.?0+$'), '')
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}
