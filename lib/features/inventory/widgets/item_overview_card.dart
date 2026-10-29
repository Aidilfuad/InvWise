import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';

/// Top card of the Item Details screen: SKU, name, current stock, unit price.
class ItemOverviewCard extends StatelessWidget {
  const ItemOverviewCard({
    super.key,
    required this.sku,
    required this.name,
    required this.currentStock,
    required this.unit,
    required this.unitPrice,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.minThreshold,
  });

  final String sku;
  final String name;
  final String currentStock;
  final String unit;
  final String unitPrice;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final String minThreshold;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SKU: $sku',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapXs,
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _StatusBadge(
                label: statusLabel,
                foreground: statusColor,
                background: statusBackground,
              ),
              _StatusBadge(
                label: 'Min Stock: $minThreshold',
                foreground: AppColors.onWarningContainer,
                background: AppColors.warningContainer,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
          AppSpacing.gapXl,
          // Scales down instead of overflowing on very narrow screens.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MetricLabel('Current Stock'),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentStock,
                          style: textTheme.headlineLarge?.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        AppSpacing.gapXs,
                        Text(
                          unit,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: AppColors.border,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MetricLabel('Unit Price'),
                    Text(
                      unitPrice,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: AppSpacing.borderRadiusFull,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _MetricLabel extends StatelessWidget {
  const _MetricLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
