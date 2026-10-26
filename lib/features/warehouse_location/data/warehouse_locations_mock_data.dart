import 'package:flutter/material.dart';

class WarehouseLocation {
  final String name;
  final String code;
  final String area;
  final int capacity;
  final int usage;
  final String status;
  final IconData icon;

  const WarehouseLocation({
    required this.name,
    required this.code,
    required this.area,
    required this.capacity,
    required this.usage,
    required this.status,
    required this.icon,
  });

  double get usageRatio => capacity == 0 ? 0 : usage / capacity;
}

class WarehouseLocationsSummary {
  final int activeLocations;
  final int totalCapacity;
  final int utilizationPercent;

  const WarehouseLocationsSummary({
    required this.activeLocations,
    required this.totalCapacity,
    required this.utilizationPercent,
  });
}

const WarehouseLocationsSummary warehouseLocationsSummary =
    WarehouseLocationsSummary(
  activeLocations: 4,
  totalCapacity: 2400,
  utilizationPercent: 78,
);

const List<WarehouseLocation> warehouseLocationsMock = [
  WarehouseLocation(
    name: 'Main Warehouse',
    code: 'WH-001',
    area: 'Shah Alam',
    capacity: 1000,
    usage: 820,
    status: 'Active',
    icon: Icons.warehouse_outlined,
  ),
  WarehouseLocation(
    name: 'Storage Room A',
    code: 'WH-002',
    area: 'Level 1',
    capacity: 500,
    usage: 320,
    status: 'Active',
    icon: Icons.meeting_room_outlined,
  ),
  WarehouseLocation(
    name: 'Receiving Area',
    code: 'WH-003',
    area: 'Dock 1',
    capacity: 400,
    usage: 210,
    status: 'Active',
    icon: Icons.local_shipping_outlined,
  ),
  WarehouseLocation(
    name: 'Production Store',
    code: 'WH-004',
    area: 'Ground Floor',
    capacity: 500,
    usage: 430,
    status: 'Active',
    icon: Icons.factory_outlined,
  ),
];