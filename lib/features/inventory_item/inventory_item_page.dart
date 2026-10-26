import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import 'data/inventory_item_mock_data.dart';
import 'widgets/inventory_item_actions.dart';
import 'widgets/inventory_item_header.dart';
import 'widgets/item_information_card.dart';
import 'widgets/notes_card.dart';
import 'widgets/stock_information_card.dart';

/// One page for both Add Item (create) and Edit Item (edit).
class InventoryItemPage extends StatefulWidget {
  const InventoryItemPage({
    super.key,
    this.mode = InventoryItemMode.create,
    this.initialItem,
  });

  final InventoryItemMode mode;

  /// Used in edit mode to pre-fill the form (mock data for now).
  final InventoryItemFormData? initialItem;

  @override
  State<InventoryItemPage> createState() => _InventoryItemPageState();
}

class _InventoryItemPageState extends State<InventoryItemPage> {
  late final TextEditingController _skuController;
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minStockController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _notesController;

  String? _category;
  String? _unit;

  bool get _isEdit => widget.mode == InventoryItemMode.edit;

  @override
  void initState() {
    super.initState();
    final item = _isEdit
        ? (widget.initialItem ?? InventoryItemMockData.sampleItem)
        : const InventoryItemFormData();

    _skuController = TextEditingController(text: item.sku);
    _nameController = TextEditingController(text: item.name);
    _quantityController = TextEditingController(text: item.quantity);
    _minStockController = TextEditingController(text: item.minStock);
    _unitPriceController = TextEditingController(text: item.unitPrice);
    _notesController = TextEditingController(text: item.notes);
    _category = item.category;
    _unit = item.unit ?? InventoryItemMockData.units.first;
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _unitPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// "Pieces (pcs)" -> "pcs"
  String get _unitShort {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(_unit ?? '');
    return match?.group(1) ?? 'pcs';
  }

  /// "pcs" -> "pc"
  String get _priceSuffix {
    final short = _unitShort;
    final singular = short.endsWith('s') && short.length > 1
        ? short.substring(0, short.length - 1)
        : short;
    return 'USD / $singular';
  }

  void _onCancel() {
    Navigator.of(context).maybePop();
  }

  void _onSubmit() {
    // TODO: Save (create) / Update (edit) item. No backend logic yet.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            InventoryItemHeader(
              title: _isEdit ? 'Edit Item' : 'Add Item',
              onBack: _onCancel,
              onSave: _onSubmit,
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    ItemInformationCard(
                      skuController: _skuController,
                      nameController: _nameController,
                      categories: InventoryItemMockData.categories,
                      units: InventoryItemMockData.units,
                      selectedCategory: _category,
                      selectedUnit: _unit,
                      onCategoryChanged: (v) => setState(() => _category = v),
                      onUnitChanged: (v) => setState(() => _unit = v),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    StockInformationCard(
                      quantityController: _quantityController,
                      minStockController: _minStockController,
                      unitPriceController: _unitPriceController,
                      unitSuffix: _unitShort,
                      priceSuffix: _priceSuffix,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    NotesCard(controller: _notesController),
                  ],
                ),
              ),
            ),
            InventoryItemActions(
              mode: widget.mode,
              onCancel: _onCancel,
              onSubmit: _onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}