import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/inventory_service.dart';
import '../activity_log/activity_log_page.dart';
import '../inventory_item/data/inventory_item_form_data.dart';
import '../inventory_item/inventory_item_page.dart';
import '../stock_adjustment/data/stock_adjustment_options.dart';
import '../stock_adjustment/stock_adjustment_page.dart';
import 'data/item_details_data.dart';
import 'widgets/activity_history_card.dart';
import 'widgets/info_grid_card.dart';
import 'widgets/item_action_buttons.dart';
import 'widgets/item_overview_card.dart';

class ItemDetailsPage extends StatefulWidget {
  const ItemDetailsPage({super.key, required this.itemId});

  final String itemId;

  static const double _maxContentWidth = 600;

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  final _service = InventoryService();
  InventoryItem? _item;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final item = await _service.getItemById(widget.itemId);
      if (!mounted) return;
      setState(() {
        _item = item;
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

  Future<void> _onEditTap() async {
    final item = _item;
    if (item == null) return;
    final updatedItem = await Navigator.of(context).push<InventoryItem>(
      MaterialPageRoute<InventoryItem>(
        builder: (_) =>
            InventoryItemPage(mode: InventoryItemMode.edit, initialItem: item),
      ),
    );
    if (updatedItem != null && mounted) {
      setState(() => _item = updatedItem);
    }
  }

  Future<void> _onDeleteTap() async {
    final item = _item;
    if (item == null || _isDeleting) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Delete "${item.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _service.deleteItem(item.id);
      if (mounted) Navigator.of(context).pop();
    } on InventoryServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _openStockAdjustment(AdjustmentType type) async {
    final item = _item;
    if (item == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => StockAdjustmentPage(itemId: item.id, initialType: type),
      ),
    );
    if (mounted) await _loadItem();
  }

  ItemDetails _detailsFor(InventoryItem item) => ItemDetails(
    sku: item.sku,
    name: item.name,
    currentStock: item.quantity,
    unit: item.unitLabel,
    unitPrice: item.unitPrice,
    warehouse: item.location ?? '—',
    binLocation: '—',
    category: item.categoryName ?? 'Uncategorized',
    minThreshold: item.minStock,
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final item = _item;
    final details = item == null ? null : _detailsFor(item);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Item Details',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (item != null && !_isDeleting) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_rounded),
              onPressed: _onEditTap,
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _onDeleteTap,
            ),
          ],
          AppSpacing.gapSm,
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ItemDetailsPage._maxContentWidth,
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : details == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage ?? 'Inventory item not found.',
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.gapMd,
                        FilledButton(
                          onPressed: _loadItem,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: AppSpacing.xxl + bottomInset,
                  ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: ItemActionButtons(
                          onAddStockTap: () =>
                              _openStockAdjustment(AdjustmentType.add),
                          onAdjustStockTap: () =>
                              _openStockAdjustment(AdjustmentType.remove),
                        ),
                      ),
                      const SizedBox(height: 40),
                      InfoGridCard(entries: details.infoEntries),
                      if (details.activities.isNotEmpty) ...[
                        const SizedBox(height: 48),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                          ),
                          child: ActivityHistoryCard(
                            activities: details.activities,
                            onViewAllTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ActivityLogPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
