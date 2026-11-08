import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/category_service.dart';
import '../../services/currency_service.dart';
import '../../services/inventory_service.dart';
import '../../services/offline_cache_service.dart';
import '../../services/password_confirmation_service.dart';
import '../../services/role_access_service.dart';
import '../../widgets/offline_sync_indicator.dart';
import '../../services/stock_movement_service.dart';
import '../stock_adjustment/data/stock_adjustment_options.dart';
import 'item_details_page.dart';
import 'widgets/category_filter_chips.dart';
import 'widgets/inventory_header.dart';
import 'widgets/inventory_item_card.dart';
import 'widgets/inventory_summary_card.dart';
import '../inventory_item/inventory_item_page.dart';
import '../settings/settings_page.dart';

enum InventoryStockFilter {
  all('All stock', null),
  archived('Archived items', null),
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
  static const double _maxContentWidth = 1120;
  static const double _fabClearance = 96;

  final _searchController = TextEditingController();
  final _service = InventoryService();
  final _stockMovementService = StockMovementService();
  final _roleAccess = RoleAccessService.instance;
  List<InventoryItem> _items = const [];
  List<InventoryItem> _archivedItems = const [];
  double _totalAssetValue = 0;
  final Set<String> _selectedItemIds = {};
  String? _selectedCategory;
  InventoryStockFilter _stockFilter = InventoryStockFilter.all;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSelectionMode = false;
  bool _isBulkActionRunning = false;

  @override
  void initState() {
    super.initState();
    OfflineCacheService.instance.addListener(_onOfflineCacheChanged);
    final cachedItems = _service.cachedItems;
    if (cachedItems != null) {
      _items = cachedItems;
      _totalAssetValue = cachedItems.fold<double>(
        0,
        (total, item) => total + item.inventoryValue,
      );
      _isLoading = false;
    }
    _loadCurrency();
    _loadInventory();
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

  @override
  void dispose() {
    OfflineCacheService.instance.removeListener(_onOfflineCacheChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onOfflineCacheChanged() {
    if (OfflineCacheService.instance.lastChangedKey != 'inventory.items') {
      return;
    }
    _refreshInventoryFromCache();
  }

  Future<void> _refreshInventoryFromCache() async {
    final items = await _service.readCachedItems();
    if (!mounted || items == null) return;
    final totalAssetValue = items.fold<double>(
      0,
      (total, item) => total + item.inventoryValue,
    );
    setState(() {
      _items = items;
      _totalAssetValue = totalAssetValue;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  Future<void> _loadInventory({bool forceRefresh = false}) async {
    if (_items.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = null);
    }

    try {
      final items = await _service.getItems(forceRefresh: forceRefresh);
      final totalAssetValue = items.fold<double>(
        0,
        (total, item) => total + item.inventoryValue,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _totalAssetValue = totalAssetValue;
        _selectedItemIds.removeWhere(
          (id) => !items.any((item) => item.id == id),
        );
        if (_selectedItemIds.isEmpty) _isSelectionMode = false;
        _isLoading = false;
      });
    } on InventoryServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load cached inventory: $error';
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
              for (final filter in InventoryStockFilter.values.where(
                (filter) =>
                    filter != InventoryStockFilter.archived ||
                    _roleAccess.allows(AppPermission.restoreArchivedInventory),
              ))
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
      if (selectedFilter == InventoryStockFilter.archived) {
        await _loadArchivedItems();
      }
    }
  }

  Future<void> _loadArchivedItems() async {
    try {
      final items = await _service.getArchivedItems();
      if (mounted) setState(() => _archivedItems = items);
    } on InventoryServiceException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _archiveItem(InventoryItem item) async {
    final failures = await _service.archiveItems([item.id]);
    if (!mounted) return;
    if (failures.isNotEmpty) {
      _showMessage(failures[item.id]!);
    } else {
      _showMessage('${item.name} archived.');
      await _loadInventory(forceRefresh: true);
    }
  }

  Future<void> _restoreItem(InventoryItem item) async {
    final failures = await _service.restoreItems([item.id]);
    if (!mounted) return;
    if (failures.isNotEmpty) {
      _showMessage(failures[item.id]!);
    } else {
      _showMessage('${item.name} restored.');
      await _loadArchivedItems();
      await _loadInventory(forceRefresh: true);
    }
  }

  Future<void> _deleteArchivedItem(InventoryItem item) async {
    if (!_roleAccess.allows(AppPermission.bulkDeleteInventory)) return;
    final confirmation = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permanently delete item?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This cannot be undone. Delete ${item.name} (${item.sku})?'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: confirmation,
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(
              dialogContext,
              confirmation.text.trim() == 'DELETE',
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    confirmation.dispose();
    if (confirmed != true || !mounted) return;
    if (!await PasswordConfirmationService.confirm(
      context,
      action: 'permanently delete this item',
    )) {
      return;
    }
    final failures = await _service.deleteItemsPermanently([item.id]);
    if (!mounted) return;
    if (failures.isNotEmpty) {
      _showMessage(failures[item.id]!);
    } else {
      _showMessage('${item.name} permanently deleted.');
      await _loadArchivedItems();
      await _loadInventory(forceRefresh: true);
    }
  }

  Future<void> _onItemTap(InventoryItem item) async {
    if (_isSelectionMode) {
      _toggleItemSelection(item);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RoleAccessGuard(
          permission: AppPermission.viewInventory,
          child: ItemDetailsPage(itemId: item.id),
        ),
      ),
    );
    if (mounted) await _loadInventory(forceRefresh: true);
  }

  void _enterSelectionMode([InventoryItem? item]) {
    if (_isBulkActionRunning) return;
    setState(() => _isSelectionMode = true);
    if (item != null) _toggleItemSelection(item);
  }

  void _cancelSelection() {
    if (_isBulkActionRunning) return;
    setState(() {
      _isSelectionMode = false;
      _selectedItemIds.clear();
    });
  }

  void _toggleItemSelection(InventoryItem item) {
    setState(() {
      if (!_isSelectionMode) _isSelectionMode = true;
      if (!_selectedItemIds.add(item.id)) _selectedItemIds.remove(item.id);
      if (_selectedItemIds.isEmpty) _isSelectionMode = false;
    });
  }

  List<InventoryItem> get _selectedItems => _items
      .followedBy(_archivedItems)
      .where((item) => _selectedItemIds.contains(item.id))
      .toList(growable: false);

  String get _selectionLabel =>
      '${_selectedItemIds.length} item${_selectedItemIds.length == 1 ? '' : 's'} selected';

  bool get _allVisibleItemsSelected =>
      _selectedItemIds.isNotEmpty &&
      visibleInventoryItems.isNotEmpty &&
      visibleInventoryItems.every((item) => _selectedItemIds.contains(item.id));

  List<InventoryItem> get visibleInventoryItems {
    final query = _searchController.text.trim().toLowerCase();
    final source = _stockFilter == InventoryStockFilter.archived
        ? _archivedItems
        : _items;
    return source
        .where((item) {
          final matchesSearch =
              query.isEmpty ||
              item.sku.toLowerCase().contains(query) ||
              item.name.toLowerCase().contains(query);
          final matchesCategory =
              _selectedCategory == null ||
              item.categoryName == _selectedCategory;
          return matchesSearch &&
              matchesCategory &&
              (_stockFilter == InventoryStockFilter.archived ||
                  _stockFilter.matches(item.status));
        })
        .toList(growable: false);
  }

  void _selectAllVisibleItems() {
    if (_isBulkActionRunning) return;
    setState(() {
      _isSelectionMode = true;
      _selectedItemIds.addAll(visibleInventoryItems.map((item) => item.id));
    });
  }

  void _clearSelection() {
    if (_isBulkActionRunning) return;
    setState(() => _selectedItemIds.clear());
  }

  Future<String?> _chooseCategory() async {
    List<Category> categories;
    try {
      categories = await CategoryService().getCategories();
    } on CategoryServiceException catch (error) {
      _showMessage(error.message);
      return null;
    }
    if (!mounted) return null;
    const uncategorizedValue = '';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Category'),
        content: SizedBox(
          width: 420,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: const Text('Uncategorized'),
                  onTap: () => Navigator.pop(dialogContext, uncategorizedValue),
                ),
                for (final category in categories)
                  ListTile(
                    title: Text(category.name),
                    subtitle: category.description == null
                        ? null
                        : Text(category.description!),
                    onTap: () => Navigator.pop(dialogContext, category.id),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<String?> _chooseWarehouse() async {
    List<InventoryLocation> locations;
    try {
      locations = await _service.getLocations();
    } on InventoryServiceException catch (error) {
      _showMessage(error.message);
      return null;
    }
    if (!mounted) return null;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Warehouse'),
        content: SizedBox(
          width: 420,
          child: locations.isEmpty
              ? const Text('No active warehouses are available.')
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final location in locations)
                        ListTile(
                          leading: const Icon(Icons.warehouse_outlined),
                          title: Text(location.name),
                          onTap: () =>
                              Navigator.pop(dialogContext, location.id),
                        ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeSelectedCategory() async {
    if (!_roleAccess.allows(AppPermission.bulkChangeCategory) ||
        _selectedItemIds.isEmpty) {
      return;
    }
    final categoryId = await _chooseCategory();
    if (categoryId == null || !mounted) return;
    final selectedIds = _selectedItemIds.toList(growable: false);
    final itemNames = {for (final item in _selectedItems) item.id: item.name};
    setState(() => _isBulkActionRunning = true);
    try {
      final failures = await _service.changeCategoryForItems(
        selectedIds,
        categoryId.isEmpty ? null : categoryId,
      );
      final succeeded = selectedIds.length - failures.length;
      await _loadInventory(forceRefresh: true);
      _showBulkOutcome(
        succeeded,
        failures,
        itemNames: itemNames,
        mayBePartiallyMoved: true,
      );
    } on InventoryServiceException catch (error) {
      _showBulkFailureForAll(error.message, itemNames);
    } finally {
      if (mounted) setState(() => _isBulkActionRunning = false);
    }
  }

  Future<void> _changeSelectedWarehouse() async {
    if (!_roleAccess.allows(AppPermission.bulkChangeWarehouse) ||
        _selectedItemIds.isEmpty) {
      return;
    }
    final destinationId = await _chooseWarehouse();
    if (destinationId == null || !mounted) return;
    final items = _selectedItems;
    final itemNames = {for (final item in items) item.id: item.name};
    setState(() => _isBulkActionRunning = true);
    final failures = <String, String>{};
    var succeeded = 0;
    try {
      final levels = await _service.getStockLevelsForItems(
        items.map((item) => item.id).toList(),
      );
      for (final item in items) {
        try {
          final itemLevels = levels[item.id] ?? const <String, double>{};
          final sources = itemLevels.entries
              .where((entry) => entry.key != destinationId && entry.value > 0)
              .toList(growable: false);
          if (sources.isEmpty) {
            if (itemLevels.values.every((quantity) => quantity <= 0)) {
              await _service.setEmptyStockLocation(
                itemId: item.id,
                locationId: destinationId,
              );
            }
          } else {
            for (final source in sources) {
              await _stockMovementService.createMovement(
                itemId: item.id,
                type: StockMovementType.transfer,
                quantity: source.value,
                sourceLocationId: source.key,
                destinationLocationId: destinationId,
                reference: 'Bulk warehouse change',
              );
            }
          }
          succeeded++;
        } on StockMovementServiceException catch (error) {
          failures[item.id] = error.message;
        } on InventoryServiceException catch (error) {
          failures[item.id] = error.message;
        }
      }
      await _loadInventory(forceRefresh: true);
      _showBulkOutcome(
        succeeded,
        failures,
        itemNames: itemNames,
        mayBePartiallyMoved: true,
      );
    } on InventoryServiceException catch (error) {
      _showBulkFailureForAll(error.message, itemNames);
    } finally {
      if (mounted) setState(() => _isBulkActionRunning = false);
    }
  }

  Future<void> _adjustSelectedStock() async {
    if (!_roleAccess.allows(AppPermission.adjustStock) ||
        _selectedItemIds.isEmpty) {
      return;
    }
    final adjustment = await showDialog<_BulkStockAdjustment>(
      context: context,
      builder: (_) => const _BulkStockAdjustmentDialog(),
    );
    if (adjustment == null || !mounted) return;
    final items = _selectedItems;
    final itemNames = {for (final item in items) item.id: item.name};
    setState(() => _isBulkActionRunning = true);
    final failures = <String, String>{};
    var succeeded = 0;
    try {
      final levels = await _service.getStockLevelsForItems(
        items.map((item) => item.id).toList(),
      );
      final locations = adjustment.direction == AdjustmentType.add
          ? await _service.getLocations()
          : const <InventoryLocation>[];
      for (final item in items) {
        try {
          final itemLevels = levels[item.id] ?? const <String, double>{};
          if (adjustment.direction == AdjustmentType.add) {
            final activeLocationIds = locations
                .map((location) => location.id)
                .toSet();
            final locationId =
                (item.locationId != null &&
                    activeLocationIds.contains(item.locationId))
                ? item.locationId
                : itemLevels.keys
                          .where(activeLocationIds.contains)
                          .firstOrNull ??
                      locations.firstOrNull?.id;
            if (locationId == null) {
              throw const InventoryServiceException(
                'No active warehouse is available for this item.',
              );
            }
            await _stockMovementService.createMovement(
              itemId: item.id,
              type: StockMovementType.receipt,
              quantity: adjustment.quantity,
              destinationLocationId: locationId,
              reference: 'Bulk stock adjustment',
            );
          } else {
            final total = itemLevels.values.fold<double>(
              0,
              (sum, quantity) => sum + quantity,
            );
            if (total < adjustment.quantity) {
              throw InventoryServiceException(
                'Only $total units are available across this item’s '
                'warehouses.',
              );
            }
            var remaining = adjustment.quantity;
            for (final level in itemLevels.entries) {
              if (remaining <= 0) break;
              if (level.value <= 0) continue;
              final quantity = level.value < remaining
                  ? level.value
                  : remaining;
              await _stockMovementService.createMovement(
                itemId: item.id,
                type: StockMovementType.issue,
                quantity: quantity,
                sourceLocationId: level.key,
                reference: 'Bulk stock adjustment',
              );
              remaining -= quantity;
            }
          }
          succeeded++;
        } on StockMovementServiceException catch (error) {
          failures[item.id] = error.message;
        } on InventoryServiceException catch (error) {
          failures[item.id] = error.message;
        }
      }
      await _loadInventory(forceRefresh: true);
      _showBulkOutcome(succeeded, failures, itemNames: itemNames);
    } on InventoryServiceException catch (error) {
      _showBulkFailureForAll(error.message, itemNames);
    } finally {
      if (mounted) setState(() => _isBulkActionRunning = false);
    }
  }

  Future<void> _archiveSelectedItems() async {
    if (!_roleAccess.allows(AppPermission.bulkArchiveInventory) ||
        _selectedItemIds.isEmpty) {
      return;
    }
    final count = _selectedItemIds.length;
    final confirmed = await _confirmBulkAction(
      title: 'Archive items?',
      message:
          'Archive $count selected items? Their inventory history will '
          'be retained.',
      confirmLabel: 'Archive',
    );
    if (confirmed != true || !mounted) return;
    final selectedIds = _selectedItemIds.toList(growable: false);
    final itemNames = {for (final item in _selectedItems) item.id: item.name};
    setState(() => _isBulkActionRunning = true);
    try {
      final failures = await _service.archiveItems(selectedIds);
      final succeeded = selectedIds.length - failures.length;
      await _loadInventory(forceRefresh: true);
      _showBulkOutcome(succeeded, failures, itemNames: itemNames);
    } on InventoryServiceException catch (error) {
      _showBulkFailureForAll(error.message, itemNames);
    } finally {
      if (mounted) setState(() => _isBulkActionRunning = false);
    }
  }

  Future<void> _deleteSelectedItems() async {
    if (!_roleAccess.allows(AppPermission.bulkDeleteInventory) ||
        _selectedItemIds.isEmpty) {
      return;
    }
    final selected = _selectedItems;
    if (selected.any((item) => !item.isArchived)) {
      _showMessage('Archive items before permanently deleting them.');
      return;
    }
    final confirmation = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permanently delete items?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This cannot be undone. Permanently delete '
              '${selected.length} selected items?',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: confirmation,
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(
              dialogContext,
              confirmation.text.trim() == 'DELETE',
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    confirmation.dispose();
    if (confirmed != true || !mounted) return;
    if (!await PasswordConfirmationService.confirm(
      context,
      action: 'permanently delete selected items',
    )) {
      return;
    }
    final selectedIds = _selectedItemIds.toList(growable: false);
    final itemNames = {for (final item in _selectedItems) item.id: item.name};
    setState(() => _isBulkActionRunning = true);
    try {
      final failures = await _service.deleteItemsPermanently(selectedIds);
      final succeeded = selectedIds.length - failures.length;
      await _loadInventory(forceRefresh: true);
      _showBulkOutcome(succeeded, failures, itemNames: itemNames);
    } on InventoryServiceException catch (error) {
      _showBulkFailureForAll(error.message, itemNames);
    } finally {
      if (mounted) setState(() => _isBulkActionRunning = false);
    }
  }

  Future<bool?> _confirmBulkAction({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  void _completeBulkAction(String message) {
    setState(() {
      _isSelectionMode = false;
      _selectedItemIds.clear();
    });
    _showMessage(message);
  }

  void _showBulkOutcome(
    int succeeded,
    Map<String, String> failures, {
    required Map<String, String> itemNames,
    bool mayBePartiallyMoved = false,
  }) {
    if (failures.isEmpty) {
      _completeBulkAction('Bulk action completed for $succeeded items.');
      return;
    }
    setState(() {
      _selectedItemIds
        ..clear()
        ..addAll(failures.keys);
      _isSelectionMode = true;
    });
    final failureSummary = failures.entries
        .map(
          (failure) =>
              '${itemNames[failure.key] ?? failure.key}: ${failure.value}',
        )
        .join('\n');
    final partialMoveWarning = mayBePartiallyMoved
        ? ' An item may have been partly moved across warehouses; review its '
              'stock movement history before retrying.'
        : '';
    _showMessage(
      '$succeeded completed; ${failures.length} failed.$partialMoveWarning\n'
      '$failureSummary',
      duration: const Duration(seconds: 10),
    );
  }

  void _showBulkFailureForAll(String message, Map<String, String> itemNames) {
    _showBulkOutcome(0, {
      for (final id in itemNames.keys) id: message,
    }, itemNames: itemNames);
  }

  void _showMessage(String message, {Duration? duration}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration ?? const Duration(seconds: 4),
        ),
      );
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
    if (mounted) await _loadInventory(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
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
    final visibleItems = visibleInventoryItems;
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
        floatingActionButton:
            !_isSelectionMode &&
                _roleAccess.allows(AppPermission.createInventory)
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth < _maxContentWidth
                ? constraints.maxWidth
                : _maxContentWidth;
            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: RefreshIndicator(
                  onRefresh: () => _loadInventory(forceRefresh: true),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: OfflineSyncIndicator()),
                      if (_isSelectionMode)
                        SliverToBoxAdapter(child: _buildBulkActionBar(context)),
                      SliverToBoxAdapter(
                        child: InventoryHeader(
                          subtitle: _isSelectionMode
                              ? 'Select items to manage'
                              : 'Inventory items',
                          userInitials: userInitials.isEmpty
                              ? 'IN'
                              : userInitials,
                          searchController: _searchController,
                          onSearchChanged: (_) => setState(() {}),
                          onFilterTap: _onFilterTap,
                          isFilterActive:
                              _stockFilter != InventoryStockFilter.all,
                          onProfileTap: _onProfileTap,
                          onSelectionTap: _isSelectionMode
                              ? _cancelSelection
                              : _enterSelectionMode,
                          isSelectionMode: _isSelectionMode,
                          topInset: _isSelectionMode ? 0 : null,
                        ),
                      ),
                      if (!_isLoading && _errorMessage == null) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.lg),
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
                                  totalAssetValue: _totalAssetValue,
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
                                  separatorBuilder: (_, _) => AppSpacing.gapLg,
                                  itemBuilder: (context, index) {
                                    final item = visibleItems[index];
                                    return InventoryItemCard(
                                      item: item,
                                      onTap: () => _onItemTap(item),
                                      onLongPress: () =>
                                          _enterSelectionMode(item),
                                      isSelectionMode: _isSelectionMode,
                                      isSelected: _selectedItemIds.contains(
                                        item.id,
                                      ),
                                      onArchive:
                                          !item.isArchived &&
                                              _roleAccess.allows(
                                                AppPermission
                                                    .bulkArchiveInventory,
                                              )
                                          ? () => _archiveItem(item)
                                          : null,
                                      onRestore:
                                          item.isArchived &&
                                              _roleAccess.allows(
                                                AppPermission
                                                    .restoreArchivedInventory,
                                              )
                                          ? () => _restoreItem(item)
                                          : null,
                                      onPermanentDelete:
                                          item.isArchived &&
                                              _roleAccess.allows(
                                                AppPermission
                                                    .bulkDeleteInventory,
                                              )
                                          ? () => _deleteArchivedItem(item)
                                          : null,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildBulkActionBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _selectionLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapXs,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              TextButton.icon(
                onPressed: _isBulkActionRunning || visibleInventoryItems.isEmpty
                    ? null
                    : _allVisibleItemsSelected
                    ? null
                    : _selectAllVisibleItems,
                icon: const Icon(Icons.select_all_rounded),
                label: const Text('Select All'),
              ),
              if (_selectedItemIds.isNotEmpty)
                TextButton.icon(
                  onPressed: _isBulkActionRunning ? null : _clearSelection,
                  icon: const Icon(Icons.remove_done_rounded),
                  label: const Text('Clear Selection'),
                ),
              if (_roleAccess.allowsAny(const {
                AppPermission.bulkChangeCategory,
                AppPermission.bulkChangeWarehouse,
                AppPermission.adjustStock,
                AppPermission.bulkArchiveInventory,
                AppPermission.bulkDeleteInventory,
              }))
                OutlinedButton.icon(
                  onPressed: _isBulkActionRunning ? null : _showBulkActions,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Bulk Actions'),
                ),
            ],
          ),
          if (_isBulkActionRunning) ...[
            AppSpacing.gapSm,
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Future<void> _showBulkActions() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final actions = <Widget>[
        if (_roleAccess.allows(AppPermission.bulkChangeCategory))
          _bulkActionButton(
            label: 'Change Category',
            icon: Icons.category_outlined,
            onPressed: () {
              Navigator.pop(sheetContext);
              _changeSelectedCategory();
            },
          ),
        if (_roleAccess.allows(AppPermission.bulkChangeWarehouse))
          _bulkActionButton(
            label: 'Change Warehouse',
            icon: Icons.warehouse_outlined,
            onPressed: () {
              Navigator.pop(sheetContext);
              _changeSelectedWarehouse();
            },
          ),
        if (_roleAccess.allows(AppPermission.adjustStock))
          _bulkActionButton(
            label: 'Stock Adjustment',
            icon: Icons.tune_rounded,
            onPressed: () {
              Navigator.pop(sheetContext);
              _adjustSelectedStock();
            },
          ),
        if (_roleAccess.allows(AppPermission.bulkArchiveInventory))
          _bulkActionButton(
            label: 'Archive Items',
            icon: Icons.archive_outlined,
            onPressed: () {
              Navigator.pop(sheetContext);
              _archiveSelectedItems();
            },
          ),
        if (_roleAccess.allows(AppPermission.bulkDeleteInventory))
          _bulkActionButton(
            label: 'Delete Items',
            icon: Icons.delete_outline_rounded,
            onPressed: () {
              Navigator.pop(sheetContext);
              _deleteSelectedItems();
            },
            destructive: true,
          ),
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bulk Actions',
                          style: Theme.of(sheetContext).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        tooltip: 'Close',
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  for (final action in actions) ...[action, AppSpacing.gapSm],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _bulkActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool destructive = false,
  }) => OutlinedButton(
    onPressed: _isBulkActionRunning || _selectedItemIds.isEmpty
        ? null
        : onPressed,
    style: destructive
        ? OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
    child: Row(
      children: [
        Icon(icon),
        AppSpacing.gapSm,
        Expanded(
          child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

class _BulkStockAdjustment {
  const _BulkStockAdjustment({required this.direction, required this.quantity});

  final AdjustmentType direction;
  final double quantity;
}

class _BulkStockAdjustmentDialog extends StatefulWidget {
  const _BulkStockAdjustmentDialog();

  @override
  State<_BulkStockAdjustmentDialog> createState() =>
      _BulkStockAdjustmentDialogState();
}

class _BulkStockAdjustmentDialogState
    extends State<_BulkStockAdjustmentDialog> {
  final _quantityController = TextEditingController();
  AdjustmentType _direction = AdjustmentType.add;
  String? _errorMessage;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    final quantity = double.tryParse(_quantityController.text.trim());
    if (quantity == null || !quantity.isFinite || quantity <= 0) {
      setState(() => _errorMessage = 'Enter a valid quantity greater than 0.');
      return;
    }
    Navigator.pop(
      context,
      _BulkStockAdjustment(direction: _direction, quantity: quantity),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Bulk Stock Adjustment'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<AdjustmentType>(
            segments: const [
              ButtonSegment(
                value: AdjustmentType.add,
                label: Text('Add'),
                icon: Icon(Icons.add_rounded),
              ),
              ButtonSegment(
                value: AdjustmentType.remove,
                label: Text('Remove'),
                icon: Icon(Icons.remove_rounded),
              ),
            ],
            selected: {_direction},
            onSelectionChanged: (selection) =>
                setState(() => _direction = selection.first),
          ),
          AppSpacing.gapMd,
          TextField(
            controller: _quantityController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Quantity per item',
              errorText: _errorMessage,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Apply')),
    ],
  );
}
