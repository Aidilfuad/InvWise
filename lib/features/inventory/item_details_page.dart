import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../stock_adjustment/data/stock_adjustment_mock_data.dart'
    show AdjustmentType;
import '../stock_adjustment/stock_adjustment_page.dart';
import 'data/item_details_mock_data.dart';
import 'widgets/activity_history_card.dart';
import 'widgets/info_grid_card.dart';
import 'widgets/item_action_buttons.dart';
import 'widgets/item_overview_card.dart';
import '../inventory_item/data/inventory_item_mock_data.dart';
import '../inventory_item/inventory_item_page.dart';
import '../activity_log/activity_log_page.dart';

/// Item Details screen. UI only, backed by dummy data.
class ItemDetailsPage extends StatelessWidget {
  const ItemDetailsPage({
    super.key,
    this.details = ItemDetailsMockData.item,
  });

  final ItemDetails details;

  static const double _maxContentWidth = 600;

  void _onBackTap(BuildContext context) {
    Navigator.of(context).maybePop();
  }

  void _onEditTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const InventoryItemPage(
          mode: InventoryItemMode.edit,
        ),
      ),
    );
  }

  void _onAddStockTap(BuildContext context) {
    _openStockAdjustment(context, type: AdjustmentType.add);
  }

  void _onAdjustStockTap(BuildContext context) {
    _openStockAdjustment(context, type: AdjustmentType.remove);
  }

  void _openStockAdjustment(
    BuildContext context, {
    AdjustmentType type = AdjustmentType.remove,
  }) {
    // TODO: Pass the current item once details come from real data.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StockAdjustmentPage(initialType: type),
      ),
    );
  }

  void _onViewAllActivityTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ActivityLogPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _onBackTap(context),
        ),
        title: Text(
          'Item Details',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _onEditTap(context),
          ),
          AppSpacing.gapSm,
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: AppSpacing.xxl + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    0,
                  ),
                  child: ItemOverviewCard(
                    sku: details.sku,
                    name: details.name,
                    currentStock: details.currentStockLabel,
                    unit: details.unit,
                    unitPrice: details.unitPriceLabel,
                  ),
                ),
                AppSpacing.gapXl,
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: ItemActionButtons(
                    onAddStockTap: () => _onAddStockTap(context),
                    onAdjustStockTap: () => _onAdjustStockTap(context),
                  ),
                ),
                const SizedBox(height: 40),
                InfoGridCard(entries: details.infoEntries),
                const SizedBox(height: 48),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: ActivityHistoryCard(
                    activities: details.activities,
                    onViewAllTap: () => _onViewAllActivityTap(context),
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