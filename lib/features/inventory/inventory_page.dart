import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/inventory_service.dart';
import '../../services/role_access_service.dart';
import 'item_details_page.dart';
import 'widgets/category_filter_chips.dart';
import 'widgets/inventory_header.dart';
import 'widgets/inventory_item_card.dart';
import 'widgets/inventory_summary_card.dart';
import '../inventory_item/inventory_item_page.dart';
import '../settings/settings_page.dart';

enum InventoryStockFilter {
  all('All stock', null),
  inStock('In stock', InventoryStockStatus.inStock),
  lowStock('Low stock', InventoryStockStatus.lowStock),
  outOfStock('Out of stock', InventoryStockStatus.outOfStock);

  const InventoryStockFilter(this.label, this.stockStatus);

  final String label;
  final InventoryStockStatus? stockStatus;

  bool matches(InventoryStockStatus status) =>
      stockStatus == null || stockStatus == status;
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  static const double _maxContentWidth = 600;
  static const double _fabClearance = 96;

  final _searchController = TextEditingController();
  final _service = InventoryService();
  final _roleAccess = RoleAccessService.instance;
  List<InventoryItem> _items = const [];
  String? _selectedCategory;
  InventoryStockFilter _stockFilter = InventoryStockFilter.all;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _service.getItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on InventoryServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  void _onProfileTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleAccessGuard(
          permission: AppPermission.viewSettings,
          child: const SettingsPage(),
        ),
      ),
    );
  }

  void _onCategorySelected(int index, List<String> categories) {
    setState(() {
      _selectedCategory = index == 0 ? null : categories[index];
    });
  }

  Future<void> _onFilterTap() async {
    final selectedFilter = await showModalBottomSheet<InventoryStockFilter>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Text(
                  'Filter by stock status',
                  style: Theme.of(sheetContext).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              for (final filter in InventoryStockFilter.values)
                ListTile(
                  title: Text(filter.label),
                  trailing: _stockFilter == filter
                      ? Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, filter),
                ),
            ],
          ),
        ),
      ),
    );
    if (selectedFilter != null && mounted) {
      setState(() => _stockFilter = selectedFilter);
    }
  }

  Future<void> _onItemTap(InventoryItem item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RoleAccessGuard(
          permission: AppPermission.viewInventory,
          child: ItemDetailsPage(itemId: item.id),
        ),
      ),
    );
    if (mounted) await _loadInventory();
  }

  Future<void> _onAddItemTap() async {
    if (!_roleAccess.allows(AppPermission.createInventory)) return;
    await Navigator.of(context).push<InventoryItem>(
      MaterialPageRoute<InventoryItem>(
        builder: (_) => RoleAccessGuard(
          permission: AppPermission.createInventory,
          child: const InventoryItemPage(),
        ),
      ),
    );
    if (mounted) await _loadInventory();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final query = _searchController.text.trim().toLowerCase();
    final categoryNames =
        _items
            .map((item) => item.categoryName)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    final categories = <String>['All Items', ...categoryNames];
    final selectedCategoryIndex = _selectedCategory == null
        ? 0
        : categories.indexOf(_selectedCategory!);
    final selectedIndex = selectedCategoryIndex < 0 ? 0 : selectedCategoryIndex;
    final visibleItems = _items
        .where((item) {
          final matchesSearch =
              query.isEmpty ||
              item.sku.toLowerCase().contains(query) ||
              item.name.toLowerCase().contains(query);
          final matchesCategory =
              _selectedCategory == null ||
              item.categoryName == _selectedCategory;
          final matchesStockStatus = _stockFilter.matches(item.status);
          return matchesSearch && matchesCategory && matchesStockStatus;
        })
        .toList(growable: false);
    final lowStockCount = _items
        .where((item) => item.status == InventoryStockStatus.lowStock)
        .length;
    final outOfStockCount = _items
        .where((item) => item.status == InventoryStockStatus.outOfStock)
        .length;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final email = currentUser?.email ?? '';
    final overlayStyle = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    final userInitials = email.isEmpty
        ? 'IN'
        : email
              .split('@')
              .first
              .split(RegExp(r'[._-]'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        floatingActionButton: _roleAccess.allows(AppPermission.createInventory)
            ? FloatingActionButton.extended(
                onPressed: _onAddItemTap,
                elevation: 4,
                shape: const StadiumBorder(),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Add Item',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            : null,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              children: [
                InventoryHeader(
                  subtitle: 'Inventory items',
                  userInitials: userInitials.isEmpty ? 'IN' : userInitials,
                  searchController: _searchController,
                  onSearchChanged: (_) => setState(() {}),
                  onFilterTap: _onFilterTap,
                  isFilterActive: _stockFilter != InventoryStockFilter.all,
                  onProfileTap: _onProfileTap,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadInventory,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (!_isLoading && _errorMessage == null) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.lg,
                              ),
                              child: CategoryFilterChips(
                                categories: categories,
                                selectedIndex: selectedIndex,
                                onSelected: (index) =>
                                    _onCategorySelected(index, categories),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              AppSpacing.lg,
                              AppSpacing.xl,
                              _fabClearance + bottomInset,
                            ),
                            sliver: SliverMainAxisGroup(
                              slivers: [
                                SliverToBoxAdapter(
                                  child: InventorySummaryCard(
                                    totalSkuCount: _items.length,
                                    lowStockCount: lowStockCount,
                                    outOfStockCount: outOfStockCount,
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.lg,
                                    ),
                                    child: Text(
                                      'Stock Items',
                                      textAlign: TextAlign.center,
                                      style: textTheme.titleSmall?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                if (visibleItems.isEmpty)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.xxl,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _items.isEmpty
                                              ? 'No inventory items yet. Add an item to get started.'
                                              : 'No items match your search or category.',
                                          textAlign: TextAlign.center,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  SliverList.separated(
                                    itemCount: visibleItems.length,
                                    separatorBuilder: (_, _) =>
                                        AppSpacing.gapLg,
                                    itemBuilder: (context, index) {
                                      final item = visibleItems[index];
                                      return InventoryItemCard(
                                        item: item,
                                        onTap: () => _onItemTap(item),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ] else
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : Padding(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.xl,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _errorMessage!,
                                            textAlign: TextAlign.center,
                                            style: textTheme.bodyMedium,
                                          ),
                                          AppSpacing.gapMd,
                                          FilledButton(
                                            onPressed: _loadInventory,
                                            child: const Text('Try Again'),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
