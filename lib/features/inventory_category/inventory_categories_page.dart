import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import 'data/inventory_categories_mock_data.dart';
import 'widgets/add_category_dialog.dart';
import 'widgets/category_card.dart';
import 'widgets/category_search_bar.dart';
import 'widgets/category_summary_footer.dart';
import 'widgets/inventory_categories_header.dart';

enum CategorySort { nameAsc, nameDesc }

class InventoryCategoriesPage extends StatefulWidget {
  const InventoryCategoriesPage({super.key});

  @override
  State<InventoryCategoriesPage> createState() =>
      _InventoryCategoriesPageState();
}

class _InventoryCategoriesPageState extends State<InventoryCategoriesPage> {
  String _query = '';
  CategorySort? _sort;

  List<InventoryCategory> get _visibleCategories {
    final query = _query.trim().toLowerCase();
    final list = InventoryCategoriesMockData.categories
        .where((c) => query.isEmpty || c.name.toLowerCase().contains(query))
        .toList();

    if (_sort != null) {
      list.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      if (_sort == CategorySort.nameDesc) {
        return list.reversed.toList();
      }
    }
    return list;
  }

  String get _sortLabel {
    switch (_sort) {
      case CategorySort.nameAsc:
        return 'Name A-Z';
      case CategorySort.nameDesc:
        return 'Name Z-A';
      case null:
        return 'Default Order';
    }
  }

  void _onBack() {
    Navigator.pop(context);
  }

  void _onAddCategoryTap() {
    AddCategoryDialog.show(context, onSave: _onSaveCategory);
  }

  void _onSaveCategory(String name, String description) {
    // TODO: Save the new category.
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
  }

  Future<void> _onSortTap() async {
    final selected = await showModalBottomSheet<CategorySort>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: AppSpacing.sm),
            _sortOption(sheetContext, CategorySort.nameAsc, 'Name A-Z'),
            _sortOption(sheetContext, CategorySort.nameDesc, 'Name Z-A'),
            SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _sort = selected);
    }
  }

  Widget _sortOption(BuildContext sheetContext, CategorySort value, String label) {
    return ListTile(
      title: Text(
        label,
        style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
      ),
      trailing: _sort == value
          ? Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () => Navigator.pop(sheetContext, value),
    );
  }

  void _onEditTap(InventoryCategory category) {
    AddCategoryDialog.show(
      context,
      initialName: category.name,
      initialDescription: category.description,
      onSave: _onSaveEditedCategory,
    );
  }

  void _onSaveEditedCategory(String name, String description) {
    // TODO: Update the category (requires backend).
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Category update will be available after backend integration.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categories = _visibleCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            InventoryCategoriesHeader(
              onBack: _onBack,
              onAddCategory: _onAddCategoryTap,
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.all(AppSpacing.lg),
                children: [
                  CategorySearchBar(onChanged: _onSearchChanged),
                  SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Text(
                        'All Categories',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${categories.length}',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Spacer(),
                      InkWell(
                        onTap: _onSortTap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_vert,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _sortLabel,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  if (categories.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No categories found.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  for (final category in categories) ...[
                    CategoryCard(
                      category: category,
                      onEdit: () => _onEditTap(category),
                    ),
                    SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            CategorySummaryFooter(
              totalItems: InventoryCategoriesMockData.totalItems,
              onAddCategory: _onAddCategoryTap,
            ),
          ],
        ),
      ),
    );
  }
}