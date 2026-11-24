import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';

/// White top section: title + subtitle + avatar, then search field and
/// filter button, closed by a hairline divider. Extends under the status bar.
class InventoryHeader extends StatelessWidget {
  const InventoryHeader({
    super.key,
    required this.subtitle,
    required this.userInitials,
    required this.searchController,
    this.title = 'Inventory',
    this.onSearchChanged,
    this.onFilterTap,
    this.isFilterActive = false,
    this.onProfileTap,
    this.onSelectionTap,
    this.isSelectionMode = false,
    this.topInset,
  });

  final String title;
  final String subtitle;
  final String userInitials;
  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterTap;
  final bool isFilterActive;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSelectionTap;
  final bool isSelectionMode;
  final double? topInset;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final effectiveTopInset = topInset ?? MediaQuery.paddingOf(context).top;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        effectiveTopInset + AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapXs,
                    Text(
                      subtitle,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapMd,
              if (onSelectionTap != null) ...[
                OutlinedButton.icon(
                  onPressed: onSelectionTap,
                  icon: Icon(
                    isSelectionMode
                        ? Icons.close_rounded
                        : Icons.checklist_rounded,
                  ),
                  label: Text(isSelectionMode ? 'Cancel' : 'Select'),
                ),
                AppSpacing.gapSm,
              ],
              Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onProfileTap,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Text(
                        userInitials,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  textInputAction: TextInputAction.search,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search SKU or Name...',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: AppSpacing.iconMd,
                      color: AppColors.textPrimary,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: AppSpacing.iconMd,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapMd,
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  side: BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onFilterTap,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: isFilterActive
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
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
