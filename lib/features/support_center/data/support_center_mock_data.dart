import 'package:flutter/material.dart';

class QuickHelpItem {
  const QuickHelpItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class SupportCenterMockData {
  const SupportCenterMockData._();

  static const List<QuickHelpItem> quickHelp = [
    QuickHelpItem(
      title: 'User Guide',
      description: 'Get started with your workspace.',
      icon: Icons.menu_book_outlined,
    ),
    QuickHelpItem(
      title: 'Inventory Help',
      description: 'Manage items and stock movements.',
      icon: Icons.inventory_2_outlined,
    ),
    QuickHelpItem(
      title: 'Reports Help',
      description: 'Create and export stock reports.',
      icon: Icons.insert_chart_outlined,
    ),
    QuickHelpItem(
      title: 'Alerts Help',
      description: 'Set thresholds and review alerts.',
      icon: Icons.notifications_none,
    ),
  ];

  static const String itSupportEmail = 'support@invwise.com';
  static const String callSupportPhone = '+60 3-1234 5678';
  static const String appVersion = 'InvWise v1.0';
  static const String organization = 'Industrial Inventory Management System';
}