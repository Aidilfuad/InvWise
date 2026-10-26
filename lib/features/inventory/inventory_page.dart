import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import 'data/inventory_mock_data.dart';
import 'item_details_page.dart';
import 'widgets/category_filter_chips.dart';
import 'widgets/inventory_header.dart';
import 'widgets/inventory_item_card.dart';
import 'widgets/inventory_summary_card.dart';
import '../inventory_item/inventory_item_page.dart';
import '../settings/settings_page.dart';

/// Inventory list screen. UI only, backed by dummy data.
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  static const double _maxContentWidth = 600;
  // Keeps the last card clear of the floating button.
  static const double _fabClearance = 96;

  final _searchController = TextEditingController();
  int _selectedCategory = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // TODO: Filter the list by SKU or name.
  }

  void _onFilterTap() {
    // TODO: Open the filter / sort sheet.
  }

  void _onProfileTap() {
      Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  void _onCategorySelected(int index) {
    setState(() => _selectedCategory = index);
    // TODO: Filter the list by the selected category.
  }

  void _onItemTap(InventoryItem item) {
    // TODO: Pass the selected item once details come from real data.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ItemDetailsPage(),
      ),
    );
  }

  void _onAddItemTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InventoryItemPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const items = InventoryMockData.items;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
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
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              children: [
                InventoryHeader(
                  subtitle: InventoryMockData.warehouseName,
                  userInitials: InventoryMockData.userInitials,
                  searchController: _searchController,
                  onSearchChanged: _onSearchChanged,
                  onFilterTap: _onFilterTap,
                  onProfileTap: _onProfileTap,
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: CategoryFilterChips(
                            categories: InventoryMockData.categories,
                            selectedIndex: _selectedCategory,
                            onSelected: _onCategorySelected,
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
                            const SliverToBoxAdapter(
                              child: InventorySummaryCard(
                                totalSkuCount: InventoryMockData.totalSkuCount,
                                lowStockCount: InventoryMockData.lowStockCount,
                                outOfStockCount:
                                    InventoryMockData.outOfStockCount,
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
                            SliverList.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) => AppSpacing.gapLg,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return InventoryItemCard(
                                  item: item,
                                  onTap: () => _onItemTap(item),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
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