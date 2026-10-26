import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../inventory/item_details_page.dart';
import '../stock_adjustment/stock_adjustment_page.dart';
import 'data/alerts_mock_data.dart';
import 'widgets/alert_card.dart';
import 'widgets/alert_section_header.dart';
import 'widgets/alerts_filter_bar.dart';
import 'widgets/alerts_header.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  AlertFilter _filter = AlertFilter.all;

  void _onFilterChanged(AlertFilter filter) {
    setState(() => _filter = filter);
  }

  void _onActionTap(AlertEntry entry) {
    switch (entry.action) {
      case AlertAction.viewItem:
      case AlertAction.viewDetails:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ItemDetailsPage()),
        );
        break;
      case AlertAction.restock:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StockAdjustmentPage()),
        );
        break;
      case AlertAction.none:
        break;
    }
  }

  List<Widget> _section({
    required String title,
    required AlertCategory category,
    required AlertFilter visibleOn,
  }) {
    if (_filter != AlertFilter.all && _filter != visibleOn) return const [];

    final entries =
        AlertsMockData.alerts.where((a) => a.category == category).toList();
    if (entries.isEmpty) return const [];

    return [
      AlertSectionHeader(title: title, count: entries.length),
      const SizedBox(height: 12),
      for (final entry in entries) ...[
        AlertCard(
          entry: entry,
          onActionTap: entry.action == AlertAction.none
              ? null
              : () => _onActionTap(entry),
        ),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 12),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.lg),
              children: [
                const AlertsHeader(),
                const SizedBox(height: 20),
                AlertsFilterBar(
                  selected: _filter,
                  onChanged: _onFilterChanged,
                ),
                const SizedBox(height: 24),
                ..._section(
                  title: 'URGENT REPLENISHMENT',
                  category: AlertCategory.urgent,
                  visibleOn: AlertFilter.urgent,
                ),
                ..._section(
                  title: 'WARNINGS',
                  category: AlertCategory.warning,
                  visibleOn: AlertFilter.warnings,
                ),
                ..._section(
                  title: 'TASKS',
                  category: AlertCategory.task,
                  visibleOn: AlertFilter.tasks,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}