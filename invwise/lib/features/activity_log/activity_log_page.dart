import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/activity_log_service.dart';
import '../../services/inventory_service.dart';
import '../../services/stock_movement_service.dart';
import 'data/activity_log_options.dart';
import 'widgets/activity_filter_chips.dart';
import 'widgets/activity_log_card.dart';
import 'widgets/activity_log_header.dart';
import 'widgets/activity_search_bar.dart';
import 'widgets/create_stock_movement_dialog.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  final StockMovementService _movementService = StockMovementService();
  final ActivityLogService _activityLogService = ActivityLogService();
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _searchController = TextEditingController();

  ActivityFilter _filter = ActivityFilter.all;
  List<ActivityLogEntry> _entries = const [];
  List<InventoryItem> _items = const [];
  List<InventoryLocation> _locations = const [];
  String _searchQuery = '';
  String? _errorMessage;
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _activityLogService.getEntries(),
        _inventoryService.getItems(),
        _inventoryService.getLocations(),
      ]);
      if (!mounted) return;
      setState(() {
        _entries = results[0] as List<ActivityLogEntry>;
        _items = results[1] as List<InventoryItem>;
        _locations = results[2] as List<InventoryLocation>;
        _isLoading = false;
      });
    } on ActivityLogServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } on StockMovementServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } on InventoryServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load activity history: $error';
        _isLoading = false;
      });
    }
  }

  List<ActivityLogEntry> get _filteredEntries {
    final selectedType = _filter.type;
    final query = _searchQuery.trim().toLowerCase();
    return _entries
        .where((entry) {
          final typeMatches =
              selectedType == null || entry.type == selectedType;
          final searchMatches =
              query.isEmpty ||
              entry.title.toLowerCase().contains(query) ||
              entry.sku.toLowerCase().contains(query) ||
              entry.description.toLowerCase().contains(query) ||
              entry.context.toLowerCase().contains(query);
          return typeMatches && searchMatches;
        })
        .toList(growable: false);
  }

  Future<void> _createMovement() async {
    if (_items.isEmpty || _locations.isEmpty) {
      _showMessage(
        _items.isEmpty
            ? 'Create an inventory item before recording a movement.'
            : 'Create a warehouse location before recording a movement.',
      );
      return;
    }
    if (_isCreating) return;
    setState(() => _isCreating = true);
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => CreateStockMovementDialog(
        items: _items,
        locations: _locations,
        onSave: _movementService.createMovement,
      ),
    );
    if (!mounted) return;
    setState(() => _isCreating = false);
    if (created == true) {
      await _loadData();
      if (mounted) {
        _showMessage(
          _movementService.lastActivityLogWarning ?? 'Stock movement recorded.',
        );
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final entries = _filteredEntries;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ActivityLogHeader(
              onBack: () => Navigator.pop(context),
              onFilter: () => setState(() => _filter = ActivityFilter.all),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  ActivitySearchBar(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  SizedBox(height: AppSpacing.md),
                  ActivityFilterChips(
                    selected: _filter,
                    onSelected: (filter) => setState(() => _filter = filter),
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        children: [
                          Row(
                            children: [
                              Text(
                                'Recent activity',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.sort,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Newest first',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.md),
                          if (entries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: Text(
                                  'No activity found.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          for (final entry in entries) ...[
                            ActivityLogCard(entry: entry),
                            SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : _createMovement,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.add),
        label: const Text('New Movement'),
      ),
    );
  }

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
