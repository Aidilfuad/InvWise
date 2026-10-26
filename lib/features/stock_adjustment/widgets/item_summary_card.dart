import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';

/// Card at the top of the screen: icon, SKU, name (ellipsized) and quantity.
class ItemSummaryCard extends StatelessWidget {
  const ItemSummaryCard({
    super.key,
    required this.sku,
    required this.name,
    required this.quantityLabel,
  });

  final String sku;
  final String name;
  final String quantityLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 24,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SKU: $sku',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF475569),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.gapXs,
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapMd,
          Text(
            quantityLabel,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
