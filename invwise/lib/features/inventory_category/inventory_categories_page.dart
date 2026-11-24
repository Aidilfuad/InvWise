import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/category_service.dart';
import '../../services/role_access_service.dart';
// Only the InventoryCategory display model is still used (by CategoryCard).
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
  final CategoryService _service = CategoryService();
  final RoleAccessService _roleAccess = RoleAccessService.instance;

  List<Category> _categories = const [];
  bool _isLoading = true;
  String? _errorMessage;

  String _query = '';
  CategorySort? _sort;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// Loads categories from Supabase.
  ///
  /// When [silent] is true (refresh after a save) the current list stays on
  /// screen and a failure is shown as a SnackBar instead of the error state.
  Future<void> _loadCategories({bool silent = false}) async {
    try {
      final categories = await _service.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
        _errorMessage = null;
      });
    } on CategoryServiceException catch (e) {
      if (!mounted) return;
      if (silent) {
        _showMessage(e.message);
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  void _onRetryTap() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _loadCategories();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<Category> get _visibleCategories {
    final query = _query.trim().toLowerCase();
    final list = _categories
        .where((c) => query.isEmpty || c.name.toLowerCase().contains(query))
        .toList();

    if (_sort != null) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (_sort == CategorySort.nameDesc) {
        return list.reversed.toList();
      }
    }
    return list;
  }

  int get _totalItems =>
      _categories.fold<int>(0, (sum, c) => sum + c.itemCount);

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

  // The categories table has no icon column, so the icon comes from the
  // name. Unknown names use a generic icon.
  IconData _iconFor(String name) {
    switch (name.trim().toLowerCase()) {
      case 'hardware':
        return Icons.hexagon_outlined;
      case 'electrical':
        return Icons.bolt_outlined;
      case 'mechanical':
        return Icons.settings_outlined;
      case 'safety equipment':
        return Icons.engineering_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  InventoryCategory _toDisplay(Category c) {
    return InventoryCategory(
      name: c.name,
      itemCount: c.itemCount,
      description: c.description ?? '',
      icon: _iconFor(c.name),
    );
  }

  void _onBack() {
    Navigator.pop(context);
  }

  void _onAddCategoryTap() {
    if (!_roleAccess.allows(AppPermission.manageCategories)) return;
    AddCategoryDialog.show(context, onSave: _createCategory);
  }

  /// Returns an error message for the dialog, or null on success.
  Future<String?> _createCategory(String name, String description) async {
    if (!_roleAccess.allows(AppPermission.manageCategories)) {
      return 'Your role does not have permission to create categories.';
    }
    try {
      await _service.createCategory(name: name, description: description);
    } on CategoryServiceException catch (e) {
      return e.message;
    }

    unawaited(_loadCategories(silent: true));
    _showMessage('Category created.');
    return null;
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

  Widget _sortOption(
    BuildContext sheetContext,
    CategorySort value,
    String label,
  ) {
    return ListTile(
      title: Text(
        label,
        style: Theme.of(sheetContext).textTheme.bodyLarge
            ?.copyWith(color: AppColors.textPrimary),
      ),
      trailing: _sort == value
          ? Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () => Navigator.pop(sheetContext, value),
    );
  }

  void _onEditTap(Category category) {
    if (!_roleAccess.allows(AppPermission.manageCategories)) return;
    AddCategoryDialog.show(
      context,
      initialName: category.name,
      initialDescription: category.description ?? '',
      onSave: (name, description) =>
          _updateCategory(category, name, description),
    );
  }

  /// Returns an error message for the dialog, or null on success.
  Future<String?> _updateCategory(
    Category category,
    String name,
    String description,
  ) async {
    if (!_roleAccess.allows(AppPermission.manageCategories)) {
      return 'Your role does not have permission to edit categories.';
    }
    try {
      await _service.updateCategory(
        id: category.id,
        name: name,
        description: description,
      );
    } on CategoryServiceException catch (e) {
      return e.message;
    }

    unawaited(_loadCategories(silent: true));
    _showMessage('Category updated.');
    return null;
  }

  Future<void> _onDeleteTap(Category category) async {
    if (!_roleAccess.allows(AppPermission.manageCategories)) return;
    int itemCount;
    try {
      itemCount = await _service.getCategoryItemCount(category.id);
    } on CategoryServiceException catch (error) {
      _showMessage(error.message);
      return;
    }
    if (!mounted) return;

    final itemDescription =
        '$itemCount inventory item${itemCount == 1 ? '' : 's'} '
        '${itemCount == 1 ? 'uses' : 'use'} this category.';
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          '$itemDescription\n\n'
          'Archiving "${category.name}" removes it from category management. '
          'It will not delete existing inventory records or their history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    try {
      await _service.deleteCategory(category.id);
      if (!mounted) return;
      setState(() {
        _categories = _categories
            .where((item) => item.id != category.id)
            .toList(growable: false);
      });
      _showMessage('Category deleted.');
    } on CategoryServiceException catch (error) {
      _showMessage(error.message);
    }
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildErrorState(TextTheme textTheme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 32, color: AppColors.danger),
          SizedBox(height: AppSpacing.sm),
          Text(
            _errorMessage ?? 'Unable to load categories.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: _onRetryTap,
            style: TextButton.styleFrom(minimumSize: Size(0, 48)),
            child: Text(
              'Try again',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
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
              onAddCategory: _roleAccess.allows(AppPermission.manageCategories)
                  ? _onAddCategoryTap
                  : null,
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
                  if (_isLoading)
                    _buildLoadingState()
                  else if (_errorMessage != null)
                    _buildErrorState(textTheme)
                  else ...[
                    if (categories.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(
                          child: Text(
                            _query.trim().isEmpty
                                ? 'No categories yet.'
                                : 'No categories found.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    for (final category in categories) ...[
                      CategoryCard(
                        category: _toDisplay(category),
                        onEdit:
                            _roleAccess.allows(AppPermission.manageCategories)
                            ? () => _onEditTap(category)
                            : null,
                        onDelete:
                            _roleAccess.allows(AppPermission.manageCategories)
                            ? () => _onDeleteTap(category)
                            : null,
                      ),
                      SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ],
              ),
            ),
            CategorySummaryFooter(
              totalItems: _totalItems,
              onAddCategory: _roleAccess.allows(AppPermission.manageCategories)
                  ? _onAddCategoryTap
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
