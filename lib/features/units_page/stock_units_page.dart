import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import 'data/stock_units_mock_data.dart';
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
  String _query = '';
  UnitSort? _sort;

  List<StockUnit> get _visibleUnits {
    final query = _query.trim().toLowerCase();
    final list = StockUnitsMockData.units
        .where((u) => query.isEmpty || u.name.toLowerCase().contains(query))
        .toList();

    if (_sort != null) {
      list.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      if (_sort == UnitSort.nameDesc) {
        return list.reversed.toList();
      }
    }
    return list;
  }

  String get _sortLabel {
    switch (_sort) {
      case UnitSort.nameAsc:
        return 'Name A-Z';
      case UnitSort.nameDesc:
        return 'Name Z-A';
      case null:
        return 'Default Order';
    }
  }

  void _onBack() {
    Navigator.pop(context);
  }

  void _onAddUnitTap() {
    AddStockUnitDialog.show(context, onSave: _onSaveUnit);
  }

  void _onSaveUnit(String name, String abbreviation, String description) {
    // TODO: Save the new stock unit.
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

    if (selected != null && mounted) {
      setState(() => _sort = selected);
    }
  }

  Widget _sortOption(BuildContext sheetContext, UnitSort value, String label) {
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

  void _onEditTap(StockUnit unit) {
    AddStockUnitDialog.show(
      context,
      initialName: unit.name,
      initialAbbreviation: unit.abbreviation,
      initialDescription: unit.description,
      onSave: _onSaveEditedUnit,
    );
  }

  void _onSaveEditedUnit(
    String name,
    String abbreviation,
    String description,
  ) {
    // TODO: Update the stock unit (requires backend).
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Unit update will be available after backend integration.',
          ),
        ),
      );
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
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.all(AppSpacing.lg),
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
                  if (units.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No units found.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  for (final unit in units) ...[
                    StockUnitCard(
                      unit: unit,
                      onEdit: () => _onEditTap(unit),
                    ),
                    SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            StockUnitsSummaryFooter(
              activeUnits: StockUnitsMockData.units.length,
              onAddUnit: _onAddUnitTap,
            ),
          ],
        ),
      ),
    );
  }
}