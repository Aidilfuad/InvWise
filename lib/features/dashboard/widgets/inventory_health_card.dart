import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../data/dashboard_data.dart';

class InventoryHealthCard extends StatelessWidget {
  const InventoryHealthCard({
    super.key,
    required this.summary,
    this.compact = false,
  });

  final DashboardInventorySummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final total = summary.totalItems;
    final flagged = summary.lowStockItems + summary.outOfStockItems;
    final health = total == 0
        ? 0
        : ((total - flagged) / total * 100).round().clamp(0, 100);
    return _SummaryCard(
      icon: Icons.health_and_safety_outlined,
      title: 'Inventory Health',
      headline: 'Total Items: $total',
      score: 'Health Score: $health%',
      scorePercent: health,
      scoreColor: health >= 80 ? AppColors.success : AppColors.warning,
      compact: compact,
      metrics: [
        _Metric('Low Stock', summary.lowStockItems, AppColors.warning),
        _Metric('Out Of Stock', summary.outOfStockItems, AppColors.danger),
        _Metric('Inactive', summary.inactiveItems, AppColors.textSecondary),
        _Metric('Archived', summary.archivedItems, AppColors.textSecondary),
      ],
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.headline,
    required this.score,
    required this.scorePercent,
    required this.scoreColor,
    required this.metrics,
    required this.compact,
  });

  final IconData icon;
  final String title;
  final String headline;
  final String score;
  final int scorePercent;
  final Color scoreColor;
  final List<_Metric> metrics;
  final bool compact;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: EdgeInsets.all(compact ? 11 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 10),
          if (!compact)
            Text(headline, style: Theme.of(context).textTheme.bodyMedium),
          if (!compact) SizedBox(height: 10),
          Wrap(
            spacing: compact ? 9 : 14,
            runSpacing: compact ? 4 : 8,
            children: [
              for (final metric in metrics)
                Text(
                  '${compact ? _shortLabel(metric.label) : metric.label}: ${metric.value}',
                  style: TextStyle(
                    color: metric.color,
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          SizedBox(height: compact ? 6 : 12),
          Text(
            compact ? 'Health $scorePercent%' : score,
            style: TextStyle(
              color: scoreColor,
              fontSize: compact ? 12 : 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );

  String _shortLabel(String value) => switch (value) {
    'Low Stock' => 'Low',
    'Out Of Stock' => 'OOS',
    'Inactive' => 'Inactive',
    'Archived' => 'Archived',
    _ => value,
  };
}
