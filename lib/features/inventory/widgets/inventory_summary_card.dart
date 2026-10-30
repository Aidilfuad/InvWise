import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';

/// Three-column statistics card: Total SKU Count / Low Stock / Out of Stock.
/// Columns are start-, center- and end-aligned, separated by thin dividers.
class InventorySummaryCard extends StatelessWidget {
  const InventorySummaryCard({
    super.key,
    required this.totalSkuCount,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  final int totalSkuCount;
  final int lowStockCount;
  final int outOfStockCount;

  // Colors follow the reference design (white text on a pale blue card).
  static Color get _background =>
      AppColors.primaryContainer.withValues(alpha: 0.6);
  static Color get _border => AppColors.primaryContainer;
  static const Color _valueColor = AppColors.textOnPrimary;
  static Color get _labelColor =>
      AppColors.textOnPrimary.withValues(alpha: 0.8);
  static Color get _dividerColor =>
      AppColors.textOnPrimary.withValues(alpha: 0.6);

  static String _format(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              label: 'Total SKU Count',
              value: _format(totalSkuCount),
              alignment: CrossAxisAlignment.start,
              labelColor: _labelColor,
              valueColor: _valueColor,
            ),
          ),
          _StatDivider(color: _dividerColor),
          Expanded(
            child: _Stat(
              label: 'Low Stock',
              value: _format(lowStockCount),
              alignment: CrossAxisAlignment.center,
              labelColor: _labelColor,
              valueColor: _valueColor,
            ),
          ),
          _StatDivider(color: _dividerColor),
          Expanded(
            child: _Stat(
              label: 'Out of Stock',
              value: _format(outOfStockCount),
              alignment: CrossAxisAlignment.end,
              labelColor: _labelColor,
              valueColor: _valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.alignment,
    required this.labelColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final CrossAxisAlignment alignment;
  final Color labelColor;
  final Color valueColor;

  TextAlign get _textAlign => switch (alignment) {
        CrossAxisAlignment.center => TextAlign.center,
        CrossAxisAlignment.end => TextAlign.end,
        _ => TextAlign.start,
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: _textAlign,
          style: textTheme.labelSmall?.copyWith(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          textAlign: _textAlign,
          style: textTheme.headlineSmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: color,
    );
  }
}
