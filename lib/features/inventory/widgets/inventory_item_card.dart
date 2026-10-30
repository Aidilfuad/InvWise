import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../services/inventory_service.dart';

/// One row in the stock list: status icon, SKU + location, centered name,
/// quantity with status, and a trailing chevron.
class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({super.key, required this.item, this.onTap});

  final InventoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borderRadius = BorderRadius.circular(16);
    final statusColor = switch (item.status) {
      InventoryStockStatus.inStock => AppColors.success,
      InventoryStockStatus.lowStock => AppColors.warning,
      InventoryStockStatus.outOfStock => AppColors.danger,
    };
    final statusBackground = switch (item.status) {
      InventoryStockStatus.inStock => AppColors.successContainer,
      InventoryStockStatus.lowStock => AppColors.warningContainer,
      InventoryStockStatus.outOfStock => AppColors.dangerContainer,
    };
    final statusIcon = switch (item.status) {
      InventoryStockStatus.inStock => Icons.check_circle_outline_rounded,
      InventoryStockStatus.lowStock => Icons.warning_amber_rounded,
      InventoryStockStatus.outOfStock => Icons.remove_circle_outline_rounded,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Icon(statusIcon, size: 24, color: statusColor),
                ),
                AppSpacing.gapLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              item.sku,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          AppSpacing.gapSm,
                          Flexible(
                            child: Text(
                              item.location ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapXs,
                      Text(
                        item.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.gapXs,
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          Text(
                            item.quantityLabel,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.borderStrong,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            item.status.label,
                            style: textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapMd,
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppSpacing.iconMd,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
