import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';

/// UI models + dummy data for the inventory list.
/// Replace with real models / repositories when the backend is connected.

enum StockStatus {
  inStock('In Stock'),
  lowStock('Low Stock'),
  outOfStock('Out of Stock');

  const StockStatus(this.label);

  final String label;

  // The reference design renders every status with the same green style
  // (check icon, green label). Change these getters to a `switch (this)` to
  // give low / out of stock their own warning / danger colors.
  Color get color => AppColors.success;
  Color get iconBackground => AppColors.successContainer;
  IconData get icon => Icons.check_circle_outline_rounded;
}

class InventoryItem {
  const InventoryItem({
    required this.sku,
    required this.name,
    required this.location,
    required this.quantity,
    required this.unit,
    required this.status,
  });

  final String sku;
  final String name;
  final String location;
  final int quantity;
  final String unit;
  final StockStatus status;

  String get quantityLabel => '$quantity $unit';
}

abstract final class InventoryMockData {
  static const String warehouseName = 'Industrial Warehouse A';
  static const String userInitials = 'JS';

  static const List<String> categories = [
    'All Items',
    'Assembly Parts',
    'Raw Materials',
  ];

  static const int totalSkuCount = 1284;
  static const int lowStockCount = 12;
  static const int outOfStockCount = 3;

  static const List<InventoryItem> items = [
    InventoryItem(
      sku: 'SKU-8829',
      name: 'Steel Bearing 40mm',
      location: 'Aisle 4, Shelf B',
      quantity: 450,
      unit: 'PCS',
      status: StockStatus.inStock,
    ),
    InventoryItem(
      sku: 'SKU-1042',
      name: 'Hydraulic Pump G-2',
      location: 'Aisle 1, Shelf D',
      quantity: 8,
      unit: 'UNITS',
      status: StockStatus.lowStock,
    ),
    InventoryItem(
      sku: 'SKU-4491',
      name: 'Industrial Drill Bit Set',
      location: 'Aisle 2, Shelf A',
      quantity: 0,
      unit: 'SETS',
      status: StockStatus.outOfStock,
    ),
    InventoryItem(
      sku: 'SKU-9920',
      name: 'Copper Wiring 100m',
      location: 'Aisle 9, Shelf C',
      quantity: 124,
      unit: 'ROLLS',
      status: StockStatus.inStock,
    ),
  ];
}
