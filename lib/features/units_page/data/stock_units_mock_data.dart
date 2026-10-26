import 'package:flutter/material.dart';

class StockUnit {
  const StockUnit({
    required this.name,
    required this.abbreviation,
    required this.description,
    required this.icon,
  });

  final String name;
  final String abbreviation;
  final String description;
  final IconData icon;
}

class StockUnitsMockData {
  const StockUnitsMockData._();

  static const List<StockUnit> units = [
    StockUnit(
      name: 'Pieces',
      abbreviation: 'PCS',
      description: 'Individual countable inventory items',
      icon: Icons.grid_view_outlined,
    ),
    StockUnit(
      name: 'Kilograms',
      abbreviation: 'KG',
      description: 'Weight measurement unit',
      icon: Icons.scale_outlined,
    ),
    StockUnit(
      name: 'Meters',
      abbreviation: 'M',
      description: 'Length measurement unit',
      icon: Icons.straighten,
    ),
    StockUnit(
      name: 'Boxes',
      abbreviation: 'BOX',
      description: 'Grouped inventory packaging',
      icon: Icons.inventory_2_outlined,
    ),
  ];
}