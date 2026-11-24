import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../services/currency_service.dart';

/// Responsive inventory metrics with an emphasized asset value.
class InventorySummaryCard extends StatelessWidget {
  const InventorySummaryCard({
    super.key,
    required this.totalSkuCount,
    required this.totalAssetValue,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  final int totalSkuCount;
  final double totalAssetValue;
  final int lowStockCount;
  final int outOfStockCount;

  static String _format(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurrencyService.instance,
      builder: (context, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x100F172A),
              blurRadius: 16,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 560;
            final assetValueStyle = Theme.of(context).textTheme.headlineSmall
                ?.copyWith(
                  color: AppColors.textOnPrimary,
                  fontSize: isCompact ? 25 : 30,
                  fontWeight: FontWeight.w800,
                );
            final metrics = [
              _Metric(
                label: 'Total SKU Count',
                value: _format(totalSkuCount),
                icon: Icons.inventory_2_outlined,
                color: AppColors.primary,
              ),
              _Metric(
                label: 'Low Stock',
                value: _format(lowStockCount),
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
              ),
              _Metric(
                label: 'Out of Stock',
                value: _format(outOfStockCount),
                icon: Icons.remove_shopping_cart_outlined,
                color: AppColors.danger,
              ),
            ];
            final columns = isCompact ? 2 : 3;
            final spacing = 10.0;
            final metricWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 16 : 20,
                    vertical: isCompact ? 16 : 18,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Asset Value',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textOnPrimary.withValues(
                            alpha: 0.88,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyService.instance.formatMyr(totalAssetValue),
                          maxLines: 1,
                          softWrap: false,
                          style: assetValueStyle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final metric in metrics)
                      SizedBox(
                        width: metricWidth,
                        child: _MetricTile(metric: metric),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Metric {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(metric.icon, size: 16, color: metric.color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
