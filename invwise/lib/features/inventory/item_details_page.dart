import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/activity_log_service.dart';
import '../../services/currency_service.dart';
import '../../services/inventory_service.dart';
import '../../services/role_access_service.dart';
import '../activity_log/activity_log_page.dart';
import '../inventory_item/data/inventory_item_form_data.dart';
import '../inventory_item/inventory_item_page.dart';
import '../stock_adjustment/data/stock_adjustment_options.dart';
import '../stock_adjustment/stock_adjustment_page.dart';
import 'data/item_details_data.dart';
import 'widgets/activity_history_card.dart';
import 'widgets/item_action_buttons.dart';
import 'widgets/item_overview_card.dart';

class ItemDetailsPage extends StatefulWidget {
  const ItemDetailsPage({super.key, required this.itemId});

  final String itemId;

  static const double _maxContentWidth = 1600;

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  final _service = InventoryService();
  final _activityService = ActivityLogService();
  final _roleAccess = RoleAccessService.instance;
  InventoryItem? _item;
  List<ActivityEntry> _activities = const [];
  String? _errorMessage;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
    _loadItem();
  }

  Future<void> _loadCurrency() async {
    try {
      await CurrencyService.instance.loadForCurrentUser();
    } on CurrencyServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load currency settings: $error')),
      );
    }
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _activities = const [];
    });

    try {
      final item = await _service.getItemById(widget.itemId);
      if (!mounted) return;
      setState(() {
        _item = item;
        _isLoading = false;
      });
      await _loadRecentActivity(item.id);
    } on InventoryServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _onEditTap() async {
    if (!_roleAccess.allows(AppPermission.editInventory)) return;
    final item = _item;
    if (item == null) return;
    final updatedItem = await Navigator.of(context).push<InventoryItem>(
      MaterialPageRoute<InventoryItem>(
        builder: (_) => RoleAccessGuard(
          permission: AppPermission.editInventory,
          child: InventoryItemPage(
            mode: InventoryItemMode.edit,
            initialItem: item,
          ),
        ),
      ),
    );
    if (updatedItem != null && mounted) {
      setState(() => _item = updatedItem);
      await _loadRecentActivity(updatedItem.id);
    }
  }

  Future<void> _onDeleteTap() async {
    if (!_roleAccess.allows(AppPermission.bulkArchiveInventory)) return;
    final item = _item;
    if (item == null || _isDeleting) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive item?'),
        content: Text(
          'Archive "${item.name}"? Its stock and activity history will be retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _service.deleteItem(item.id);
      if (mounted) {
        final activityWarning = _service.lastActivityLogWarning;
        if (activityWarning != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(activityWarning)));
        }
        Navigator.of(context).pop();
      }
    } on InventoryServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _openStockAdjustment(AdjustmentType type) async {
    if (!_roleAccess.allows(AppPermission.adjustStock)) return;
    final item = _item;
    if (item == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RoleAccessGuard(
          permission: type == AdjustmentType.add
              ? AppPermission.receiveStock
              : AppPermission.issueStock,
          additionalPermissions: const {AppPermission.adjustStock},
          child: StockAdjustmentPage(itemId: item.id, initialType: type),
        ),
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
    inventoryValue: item.inventoryValue,
    warehouse: item.location ?? 'Not Available',
    category: item.categoryName ?? 'Uncategorized',
    minThreshold: item.minStock,
    description: item.description?.trim().isNotEmpty == true
        ? item.description!.trim()
        : 'Not Available',
    notes: item.notes?.trim().isNotEmpty == true
        ? item.notes!.trim()
        : 'No notes available',
    activities: _activities,
  );

  Future<void> _loadRecentActivity(String itemId) async {
    try {
      final entries = await _activityService.getEntries(
        limit: 5,
        itemId: itemId,
      );
      if (!mounted) return;
      final localizations = MaterialLocalizations.of(context);
      setState(() {
        _activities = entries
            .map((entry) {
              final amountLabel = entry.quantityLabel.replaceFirst(
                RegExp(r'\s*units$'),
                '',
              );
              final occurredAt = entry.occurredAt.toLocal();
              return ActivityEntry(
                title: switch (entry.type) {
                  ActivityEventType.receipt => 'Stock Receipt',
                  ActivityEventType.issue => 'Stock Issue',
                  ActivityEventType.stockAdjustment => 'Stock Adjustment',
                  ActivityEventType.returnItem => 'Stock Return',
                  ActivityEventType.transfer => 'Stock Transfer',
                  _ => entry.type.label,
                },
                date:
                    '${localizations.formatMediumDate(occurredAt)} '
                    '${TimeOfDay.fromDateTime(occurredAt).format(context)}',
                actor: 'Not Available',
                amountLabel: amountLabel,
                type: switch (entry.type) {
                  ActivityEventType.receipt ||
                  ActivityEventType.returnItem => ActivityType.received,
                  ActivityEventType.issue => ActivityType.fulfilled,
                  _ => ActivityType.adjustment,
                },
              );
            })
            .toList(growable: false);
      });
    } on ActivityLogServiceException {
      if (mounted) setState(() => _activities = const []);
    }
  }

  String _metadataValue(String? value) =>
      value?.trim().isNotEmpty == true ? value!.trim() : 'Not Available';

  String _dateValue(BuildContext context, DateTime? value) {
    if (value == null) return 'Not Available';
    final date = value.toLocal();
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(date)} '
        '${TimeOfDay.fromDateTime(date).format(context)}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final item = _item;
    final details = item == null ? null : _detailsFor(item);

    return AnimatedBuilder(
      animation: CurrencyService.instance,
      builder: (context, _) => Scaffold(
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
              if (_roleAccess.allows(AppPermission.editInventory))
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: _onEditTap,
                ),
              if (_roleAccess.allows(AppPermission.bulkArchiveInventory))
                IconButton(
                  tooltip: 'Archive',
                  icon: const Icon(Icons.archive_outlined),
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
        body: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: AppSpacing.xxl + bottomInset),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ItemDetailsPage._maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  0,
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : details == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_errorMessage ?? 'Inventory item not found.'),
                          AppSpacing.gapMd,
                          FilledButton(
                            onPressed: _loadItem,
                            child: const Text('Try Again'),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ItemOverviewCard(
                            sku: details.sku,
                            name: details.name,
                            currentStock: details.currentStockLabel,
                            unit: details.unit,
                            unitPrice: details.unitPriceLabel,
                            inventoryValue: details.inventoryValueLabel,
                            statusLabel: _stockStatusLabel(item!),
                            statusColor: _stockStatusColor(item),
                            statusBackground: _stockStatusBackground(item),
                            minThreshold:
                                '${details.minThresholdLabel} ${details.unit}',
                          ),
                          AppSpacing.gapMd,
                          ItemActionButtons(
                            onAddStockTap:
                                _roleAccess.allowsAny(const {
                                  AppPermission.receiveStock,
                                  AppPermission.adjustStock,
                                })
                                ? () => _openStockAdjustment(AdjustmentType.add)
                                : null,
                            onAdjustStockTap:
                                _roleAccess.allowsAny(const {
                                  AppPermission.issueStock,
                                  AppPermission.adjustStock,
                                })
                                ? () => _openStockAdjustment(
                                    AdjustmentType.remove,
                                  )
                                : null,
                          ),
                          AppSpacing.gapMd,
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 760;
                              final cardWidth = isWide
                                  ? (constraints.maxWidth - AppSpacing.md) / 2
                                  : constraints.maxWidth;
                              return Wrap(
                                spacing: AppSpacing.md,
                                runSpacing: AppSpacing.md,
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    child: _DetailsCard(
                                      title: 'Item Information',
                                      fields: [
                                        _DetailFieldValue('SKU', details.sku),
                                        _DetailFieldValue(
                                          'Item Name',
                                          details.name,
                                        ),
                                        _DetailFieldValue(
                                          'Description',
                                          details.description,
                                          fullWidth: true,
                                        ),
                                        _DetailFieldValue(
                                          'Category',
                                          details.category,
                                        ),
                                        _DetailFieldValue('Unit', item.unit),
                                        _DetailFieldValue(
                                          'Warehouse',
                                          details.warehouse,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _DetailsCard(
                                      title: 'Stock Information',
                                      fields: [
                                        _DetailFieldValue(
                                          'Current Stock',
                                          '${details.currentStockLabel} '
                                              '${details.unit}',
                                        ),
                                        _DetailFieldValue(
                                          'Minimum Stock Threshold',
                                          '${details.minThresholdLabel} '
                                              '${details.unit}',
                                        ),
                                        _DetailFieldValue(
                                          'Stock Status',
                                          _stockStatusLabel(item),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _DetailsCard(
                                      title: 'Financial Information',
                                      fields: [
                                        _DetailFieldValue(
                                          'Unit Price',
                                          details.unitPriceLabel,
                                        ),
                                        _DetailFieldValue(
                                          'Inventory Value',
                                          details.inventoryValueLabel,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _DetailsCard(
                                      title: 'Notes',
                                      fields: [
                                        _DetailFieldValue(
                                          'User Notes',
                                          details.notes,
                                          fullWidth: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: constraints.maxWidth,
                                    child: _DetailsCard(
                                      title: 'Metadata',
                                      fields: [
                                        _DetailFieldValue(
                                          'Created By',
                                          _metadataValue(item.createdBy),
                                        ),
                                        _DetailFieldValue(
                                          'Created Date',
                                          _dateValue(context, item.createdAt),
                                        ),
                                        _DetailFieldValue(
                                          'Last Updated By',
                                          _metadataValue(item.updatedBy),
                                        ),
                                        _DetailFieldValue(
                                          'Last Updated Date',
                                          _dateValue(context, item.updatedAt),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (details.activities.isNotEmpty) ...[
                            AppSpacing.gapMd,
                            ActivityHistoryCard(
                              activities: details.activities,
                              onViewAllTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => RoleAccessGuard(
                                      permission: AppPermission.viewActivityLog,
                                      child: const ActivityLogPage(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _stockStatusLabel(InventoryItem item) => switch (item.status) {
    InventoryStockStatus.outOfStock => 'Out Of Stock',
    InventoryStockStatus.lowStock => 'Low Stock',
    InventoryStockStatus.inStock => 'In Stock',
  };

  Color _stockStatusColor(InventoryItem item) => switch (item.status) {
    InventoryStockStatus.outOfStock => AppColors.danger,
    InventoryStockStatus.lowStock => AppColors.warning,
    InventoryStockStatus.inStock => AppColors.success,
  };

  Color _stockStatusBackground(InventoryItem item) => switch (item.status) {
    InventoryStockStatus.outOfStock => AppColors.dangerContainer,
    InventoryStockStatus.lowStock => AppColors.warningContainer,
    InventoryStockStatus.inStock => AppColors.successContainer,
  };
}

class _DetailFieldValue {
  const _DetailFieldValue(this.label, this.value, {this.fullWidth = false});

  final String label;
  final String value;
  final bool fullWidth;
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.title, required this.fields});

  final String title;
  final List<_DetailFieldValue> fields;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapMd,
          LayoutBuilder(
            builder: (context, constraints) {
              final hasTwoColumns = constraints.maxWidth >= 440;
              final fieldWidth = hasTwoColumns
                  ? (constraints.maxWidth - AppSpacing.md) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final field in fields)
                    SizedBox(
                      width: field.fullWidth || !hasTwoColumns
                          ? constraints.maxWidth
                          : fieldWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field.label,
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppSpacing.gapXs,
                          Text(
                            field.value,
                            softWrap: true,
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
