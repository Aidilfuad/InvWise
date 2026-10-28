import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/unit_service.dart';
import 'widgets/add_stock_unit_dialog.dart';
import 'widgets/stock_unit_card.dart';
import 'widgets/stock_units_header.dart';
import 'widgets/stock_units_search_bar.dart';
import 'widgets/stock_units_summary_footer.dart';

enum UnitSort { nameAsc, nameDesc }

class StockUnitsPage extends StatefulWidget {
  const StockUnitsPage({super.key});

  @override
  State<StockUnitsPage> createState() => _StockUnitsPageState();
}

class _StockUnitsPageState extends State<StockUnitsPage> {
  final _service = UnitService();
  String _query = '';
  UnitSort? _sort;
  List<MeasurementUnit> _units = const [];
  String? _errorMessage;
  bool _isLoading = true;

  List<MeasurementUnit> get _visibleUnits {
    final query = _query.trim().toLowerCase();
    final list = _units
        .where(
          (unit) =>
              query.isEmpty ||
              unit.name.toLowerCase().contains(query) ||
              unit.abbreviation.toLowerCase().contains(query) ||
              (unit.description?.toLowerCase().contains(query) ?? false),
        )
        .toList();

    if (_sort != null) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (_sort == UnitSort.nameDesc) return list.reversed.toList();
    }
    return list;
  }

  String get _sortLabel => switch (_sort) {
    UnitSort.nameAsc => 'Name A-Z',
    UnitSort.nameDesc => 'Name Z-A',
    null => 'Default Order',
  };

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final units = await _service.getUnits();
      if (!mounted) return;
      setState(() {
        _units = units;
        _isLoading = false;
      });
    } on UnitServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  void _onBack() => Navigator.pop(context);

  Future<void> _onAddUnitTap() async {
    await AddStockUnitDialog.show(context, onSave: _onSaveUnit);
  }

  Future<String?> _onSaveUnit(
    String name,
    String abbreviation,
    String description,
  ) async {
    try {
      await _service.createUnit(
        name: name,
        abbreviation: abbreviation,
        description: description,
      );
      await _loadUnits();
      return null;
    } on UnitServiceException catch (e) {
      return e.message;
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
  }

  Future<void> _onSortTap() async {
    final selected = await showModalBottomSheet<UnitSort>(
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
            _sortOption(sheetContext, UnitSort.nameAsc, 'Name A-Z'),
            _sortOption(sheetContext, UnitSort.nameDesc, 'Name Z-A'),
            SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (selected != null && mounted) setState(() => _sort = selected);
  }

  Widget _sortOption(BuildContext sheetContext, UnitSort value, String label) {
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

  Future<void> _onEditTap(MeasurementUnit unit) async {
    await AddStockUnitDialog.show(
      context,
      initialName: unit.name,
      initialAbbreviation: unit.abbreviation,
      initialDescription: unit.description,
      onSave: (name, abbreviation, description) =>
          _onSaveEditedUnit(unit.id, name, abbreviation, description),
    );
  }

  Future<String?> _onSaveEditedUnit(
    String id,
    String name,
    String abbreviation,
    String description,
  ) async {
    try {
      await _service.updateUnit(
        id: id,
        name: name,
        abbreviation: abbreviation,
        description: description,
      );
      await _loadUnits();
      return null;
    } on UnitServiceException catch (e) {
      return e.message;
    }
  }

  Future<void> _onDeleteTap(MeasurementUnit unit) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete unit?'),
        content: Text('Delete "${unit.name}" (${unit.abbreviation})?'),
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

    try {
      await _service.deleteUnit(unit.id);
      await _loadUnits();
    } on UnitServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final units = _visibleUnits;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            StockUnitsHeader(onBack: _onBack, onAddUnit: _onAddUnitTap),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadUnits,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    StockUnitsSearchBar(onChanged: _onSearchChanged),
                    SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Text(
                          'All Units',
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
                            '${units.length}',
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
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                        child: Column(
                          children: [
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: _loadUnits,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    else if (units.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                        child: Center(
                          child: Text(
                            'No units found.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      for (final unit in units) ...[
                        StockUnitCard(
                          unit: unit,
                          onEdit: () => _onEditTap(unit),
                          onDelete: () => _onDeleteTap(unit),
                        ),
                        SizedBox(height: AppSpacing.md),
                      ],
                  ],
                ),
              ),
            ),
            StockUnitsSummaryFooter(
              activeUnits: _units.length,
              onAddUnit: _onAddUnitTap,
            ),
          ],
        ),
      ),
    );
  }
}
