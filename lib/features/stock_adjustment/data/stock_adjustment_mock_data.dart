import 'package:flutter/material.dart';

/// UI models + dummy data for the Stock Adjustment screen.
/// Replace with real models / repositories when the backend is connected.

enum AdjustmentType {
  add('Add Stock', Icons.add_circle_outline_rounded),
  remove('Remove Stock', Icons.remove_circle_outline_rounded);

  const AdjustmentType(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum ReasonCode {
  restock('Restock', Icons.factory_rounded),
  production('Production', Icons.engineering_rounded),
  returned('Return', Icons.assignment_return_rounded),
  damaged('Damaged', Icons.warning_rounded),
  auditFix('Audit Fix', Icons.fact_check_outlined);

  const ReasonCode(this.label, this.icon);

  final String label;
  final IconData icon;
}

class StockAdjustmentItem {
  const StockAdjustmentItem({
    required this.sku,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.location,
  });

  final String sku;
  final String name;
  final int quantity;
  final String unit;
  final String location;

  String get quantityLabel {
    final grouped = quantity.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
    return '$grouped $unit';
  }

  String get unitLabel => unit.toUpperCase();
}

abstract final class StockAdjustmentMockData {
  static const StockAdjustmentItem item = StockAdjustmentItem(
    sku: 'IND-9920-B',
    name: 'Industrial Grade Steel Bolt',
    quantity: 1240,
    unit: 'pcs',
    location: 'North Wing - Aisle 4 - Shelf B',
  );
}
