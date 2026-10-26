import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';

/// Shared white card shell used by all Inventory Item cards.
class InventoryItemCardShell extends StatelessWidget {
  const InventoryItemCardShell({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

BoxDecoration _fieldDecoration() => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    );

/// Floating-label style text field matching the screenshot.
class InventoryItemField extends StatelessWidget {
  const InventoryItemField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.suffix,
    this.prefix,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? suffix;
  final String? prefix;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _fieldDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    prefixText: prefix,
                    prefixStyle: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    hintStyle: textTheme.bodyLarge
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          if (suffix != null) ...[
            SizedBox(width: AppSpacing.sm),
            Text(
              suffix!,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Floating-label style dropdown matching the screenshot.
class InventoryItemDropdown extends StatelessWidget {
  const InventoryItemDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _fieldDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              hint: Text(
                'Select',
                style: textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              items: items
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class ItemInformationCard extends StatelessWidget {
  const ItemInformationCard({
    super.key,
    required this.skuController,
    required this.nameController,
    required this.categories,
    required this.units,
    required this.selectedCategory,
    required this.selectedUnit,
    required this.onCategoryChanged,
    required this.onUnitChanged,
  });

  final TextEditingController skuController;
  final TextEditingController nameController;
  final List<String> categories;
  final List<String> units;
  final String? selectedCategory;
  final String? selectedUnit;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return InventoryItemCardShell(
      title: 'Item Information',
      child: Column(
        children: [
          InventoryItemField(
            label: 'SKU',
            controller: skuController,
            hint: 'e.g. FST-0842',
          ),
          SizedBox(height: AppSpacing.md),
          InventoryItemField(
            label: 'Item Name',
            controller: nameController,
            hint: 'Enter item name',
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: InventoryItemDropdown(
                  label: 'Category',
                  value: selectedCategory,
                  items: categories,
                  onChanged: onCategoryChanged,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: InventoryItemDropdown(
                  label: 'Unit',
                  value: selectedUnit,
                  items: units,
                  onChanged: onUnitChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}