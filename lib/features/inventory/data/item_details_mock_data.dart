import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';

/// UI models + dummy data for the Item Details screen.
/// Replace with real models / repositories when the backend is connected.

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

  /// Color of the quantity change shown on the right of the row.
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
    required this.activities,
  });

  final String sku;
  final String name;
  final int currentStock;
  final String unit;
  final double unitPrice;
  final String warehouse;
  final String binLocation;
  final String category;
  final int minThreshold;
  final List<ActivityEntry> activities;

  String get currentStockLabel => currentStock.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );

  String get unitPriceLabel => '\$${unitPrice.toStringAsFixed(2)}';

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
          value: '$minThreshold $unit',
        ),
      ];
}

abstract final class ItemDetailsMockData {
  static const ItemDetails item = ItemDetails(
    sku: 'INV-8829-XL',
    name: 'Industrial Grade Steel Bolt',
    currentStock: 1240,
    unit: 'units',
    unitPrice: 4.25,
    warehouse: 'North Wing - Aisle 4',
    binLocation: 'B-102-04',
    category: 'Fasteners',
    minThreshold: 200,
    activities: [
      ActivityEntry(
        title: 'Stock Received',
        date: 'Oct 24',
        actor: 'John Smith',
        amount: 500,
        type: ActivityType.received,
      ),
      ActivityEntry(
        title: 'Order Fulfilled',
        date: 'Oct 22',
        actor: 'System',
        amount: -120,
        type: ActivityType.fulfilled,
      ),
      ActivityEntry(
        title: 'Manual Adjustment',
        date: 'Oct 20',
        actor: 'Sarah Lee',
        amount: -5,
        type: ActivityType.adjustment,
      ),
    ],
  );
}
