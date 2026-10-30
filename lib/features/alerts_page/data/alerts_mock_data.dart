import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';

enum AlertFilter { all, urgent, warnings, tasks }

enum AlertCategory { urgent, warning, task }

enum AlertAction { none, viewItem, restock, viewDetails }

class AlertEntry {
  const AlertEntry({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.subtitleIsCritical = false,
    this.sku,
    this.location,
    this.expected,
    this.actual,
    this.dueLabel,
    this.actionLabel,
    this.action = AlertAction.none,
    this.primaryButton = false,
  });

  final AlertCategory category;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool subtitleIsCritical;
  final String? sku;
  final String? location;
  final String? expected;
  final String? actual;
  final String? dueLabel;
  final String? actionLabel;
  final AlertAction action;
  final bool primaryButton;
}

abstract final class AlertsMockData {
  static List<AlertEntry> get alerts => [
    AlertEntry(
      category: AlertCategory.urgent,
      title: 'Critical Stock Out',
      subtitle: 'Production line A halted',
      subtitleIsCritical: true,
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.danger,
      iconBackground: AppColors.dangerContainer,
      sku: 'TX-909-B',
      location: 'Warehouse A-12',
      actionLabel: 'View Item',
      action: AlertAction.viewItem,
      primaryButton: true,
    ),
    AlertEntry(
      category: AlertCategory.urgent,
      title: 'Low Stock: Steel Bolts',
      subtitle: 'Below safety threshold',
      icon: Icons.inventory_2_outlined,
      iconColor: AppColors.warning,
      iconBackground: AppColors.warningContainer,
      sku: 'SB-22-001',
      location: 'Warehouse B-04',
      actionLabel: 'Restock',
      action: AlertAction.restock,
    ),
    AlertEntry(
      category: AlertCategory.warning,
      title: 'Expiring Soon',
      subtitle: 'Batch #882 expires in 4 days',
      icon: Icons.schedule_rounded,
      iconColor: AppColors.warning,
      iconBackground: AppColors.warningContainer,
      sku: 'CH-44-P',
      location: 'Cold Storage',
    ),
    AlertEntry(
      category: AlertCategory.warning,
      title: 'Inventory Mismatch',
      subtitle: '',
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.warning,
      iconBackground: AppColors.warningContainer,
      expected: '120',
      actual: '115',
      actionLabel: 'View Item',
      action: AlertAction.viewItem,
    ),
    AlertEntry(
      category: AlertCategory.task,
      title: 'Cycle Count Due',
      subtitle: 'Warehouse A',
      icon: Icons.fact_check_outlined,
      iconColor: AppColors.primary,
      iconBackground: AppColors.primaryContainer,
      dueLabel: 'Due Today',
      actionLabel: 'View Details',
      action: AlertAction.viewDetails,
    ),
  ];
}