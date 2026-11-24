import 'package:flutter/material.dart';

class InventoryCategory {
  const InventoryCategory({
    required this.name,
    required this.itemCount,
    required this.description,
    required this.icon,
  });

  final String name;
  final int itemCount;
  final String description;
  final IconData icon;
}

class InventoryCategoriesMockData {
  const InventoryCategoriesMockData._();

  static const List<InventoryCategory> categories = [
    InventoryCategory(
      name: 'Hardware',
      itemCount: 342,
      description: 'Bolts, nuts, fasteners and industrial hardware',
      icon: Icons.hexagon_outlined,
    ),
    InventoryCategory(
      name: 'Electrical',
      itemCount: 186,
      description: 'Sensors, relays, PLC components and wiring',
      icon: Icons.bolt_outlined,
    ),
    InventoryCategory(
      name: 'Mechanical',
      itemCount: 128,
      description: 'Bearings, belts, motors and moving parts',
      icon: Icons.settings_outlined,
    ),
    InventoryCategory(
      name: 'Safety Equipment',
      itemCount: 45,
      description: 'PPE and workplace safety equipment',
      icon: Icons.engineering_outlined,
    ),
  ];

  static int get totalItems =>
      categories.fold<int>(0, (sum, c) => sum + c.itemCount);
}