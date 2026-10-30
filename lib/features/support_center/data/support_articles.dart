import 'package:flutter/material.dart';

class SupportArticle {
  const SupportArticle({
    required this.title,
    required this.description,
    required this.content,
    required this.icon,
    required this.keywords,
  });

  final String title;
  final String description;
  final String content;
  final IconData icon;
  final List<String> keywords;
}

abstract final class SupportArticles {
  static const List<SupportArticle> all = [
    SupportArticle(
      title: 'Getting Started',
      description: 'Sign in and navigate your workspace.',
      content:
          'Sign in with your company account. The Dashboard provides a '
          'summary of inventory and recent activity. Use the navigation bar '
          'to open Inventory, Reports, Activity, and Settings.',
      icon: Icons.menu_book_outlined,
      keywords: ['login', 'dashboard', 'navigation', 'account'],
    ),
    SupportArticle(
      title: 'Inventory Items',
      description: 'Create, edit, and review inventory records.',
      content:
          'Open Inventory to search or filter items. Select an item to view '
          'its details and stock by location. Use Add Item to create a record; '
          'select an existing item to edit its information.',
      icon: Icons.inventory_2_outlined,
      keywords: ['item', 'sku', 'create', 'edit', 'quantity', 'stock'],
    ),
    SupportArticle(
      title: 'Stock Adjustments',
      description: 'Record stock added or removed from a location.',
      content:
          'Open an item and choose Add Stock or Adjust Stock. Select the '
          'warehouse location, enter the quantity and reason, then submit. '
          'The stock level and movement history update after the adjustment '
          'is saved.',
      icon: Icons.swap_vert_rounded,
      keywords: ['adjust', 'add', 'remove', 'warehouse', 'movement'],
    ),
    SupportArticle(
      title: 'Reports and Exports',
      description: 'Review inventory data and export reports.',
      content:
          'Open Reports to choose a report type and review the results. '
          'For wide tables, scroll horizontally to see every column. Use the '
          'export actions on the report page to download or share available '
          'report formats.',
      icon: Icons.insert_chart_outlined,
      keywords: ['report', 'export', 'excel', 'download', 'table'],
    ),
  ];
}
