import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/category_service.dart';
import '../../services/inventory_service.dart';
import '../../services/unit_service.dart';
import 'data/inventory_item_form_data.dart';
import 'widgets/inventory_item_actions.dart';
import 'widgets/inventory_item_header.dart';
import 'widgets/item_information_card.dart';
import 'widgets/notes_card.dart';
import 'widgets/stock_information_card.dart';

class InventoryItemPage extends StatefulWidget {
  const InventoryItemPage({
    super.key,
    this.mode = InventoryItemMode.create,
    this.initialItem,
  });

  final InventoryItemMode mode;
  final InventoryItem? initialItem;

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

  final _inventoryService = InventoryService();
  final _categoryService = CategoryService();
  final _unitService = UnitService();
  List<Category> _categories = const [];
  List<MeasurementUnit> _units = const [];
  List<InventoryLocation> _locations = const [];
  String? _categoryId;
  String? _unitId;
  String? _locationId;
  String? _categoryLoadError;
  String? _unitLoadError;
  String? _locationLoadError;
  bool _isLoadingCategories = true;
  bool _isLoadingUnits = true;
  bool _isLoadingLocations = true;
  bool _isSaving = false;

  bool get _isEdit => widget.mode == InventoryItemMode.edit;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _skuController = TextEditingController(text: item?.sku ?? '');
    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController = TextEditingController(
      text: item?.locationQuantity.toString() ?? '',
    );
    _minStockController = TextEditingController(
      text: item?.minStock.toString() ?? '',
    );
    _unitPriceController = TextEditingController(
      text: item?.unitPrice.toString() ?? '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');
    _categoryId = item?.categoryId;
    _unitId = item?.unitId;
    _locationId = item?.locationId;
    _loadCategories();
    _loadUnits();
    _loadLocations();
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

  String get _unitShort {
    final unit = _units.where((unit) => unit.id == _unitId).firstOrNull;
    return unit?.abbreviation ?? '';
  }

  String get _priceSuffix {
    final short = _unitShort;
    final singular = short.endsWith('s') && short.length > 1
        ? short.substring(0, short.length - 1)
        : short;
    return 'USD / $singular';
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryLoadError = null;
    });

    try {
      final categories = await _categoryService.getCategories(
        includeInactive: true,
      );
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        if (_categoryId != null &&
            !categories.any((category) => category.id == _categoryId)) {
          _categoryId = null;
        }
      });
    } on CategoryServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _categoryLoadError = e.message;
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoadingUnits = true;
      _unitLoadError = null;
    });

    try {
      final units = await _unitService.getUnits();
      if (!mounted) return;
      setState(() {
        _units = units;
        _isLoadingUnits = false;
        if (_unitId != null && !units.any((unit) => unit.id == _unitId)) {
          _unitId = null;
        }
      });
    } on UnitServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _unitLoadError = e.message;
        _isLoadingUnits = false;
      });
    }
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoadingLocations = true;
      _locationLoadError = null;
    });

    try {
      final locations = await _inventoryService.getLocations();
      if (!mounted) return;
      setState(() {
        _locations = locations;
        _isLoadingLocations = false;
        if (_locationId != null &&
            !locations.any((location) => location.id == _locationId)) {
          _locationId = null;
        }
      });
    } on InventoryServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _locationLoadError = e.message;
        _isLoadingLocations = false;
      });
    }
  }

  void _onCancel() {
    Navigator.of(context).maybePop();
  }

  Future<void> _onSubmit() async {
    if (_isSaving ||
        _isLoadingCategories ||
        _isLoadingUnits ||
        _isLoadingLocations ||
        _categoryLoadError != null ||
        _unitLoadError != null ||
        _locationLoadError != null) {
      return;
    }

    final quantity = _parseNonNegativeDouble(
      _quantityController.text,
      'quantity',
    );
    final minStock = _parseNonNegativeDouble(
      _minStockController.text,
      'minimum stock',
    );
    final unitPrice = _parseNonNegativeDouble(
      _unitPriceController.text,
      'unit price',
    );
    final inputError = quantity.error ?? minStock.error ?? unitPrice.error;
    if (inputError != null) {
      _showMessage(inputError);
      return;
    }
    if (_skuController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty) {
      _showMessage('Please enter an SKU and item name.');
      return;
    }
    if (_isEdit && widget.initialItem == null) {
      _showMessage('The item to edit could not be loaded.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final item = _isEdit
          ? await _inventoryService.updateItem(
              id: widget.initialItem!.id,
              sku: _skuController.text,
              name: _nameController.text,
              categoryId: _categoryId,
              unitId: _unitId ?? '',
              locationId: _locationId ?? '',
              quantity: quantity.value!,
              minStock: minStock.value!,
              unitPrice: unitPrice.value!,
              notes: _notesController.text,
            )
          : await _inventoryService.createItem(
              sku: _skuController.text,
              name: _nameController.text,
              categoryId: _categoryId,
              unitId: _unitId ?? '',
              locationId: _locationId ?? '',
              quantity: quantity.value!,
              minStock: minStock.value!,
              unitPrice: unitPrice.value!,
              notes: _notesController.text,
            );
      if (!mounted) return;
      Navigator.of(context).pop(item);
    } on InventoryServiceException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  ({double? value, String? error}) _parseNonNegativeDouble(
    String text,
    String label,
  ) {
    final double? value = text.trim().isEmpty
        ? 0
        : double.tryParse(text.trim());
    if (value == null || !value.isFinite || value < 0) {
      return (value: null, error: 'Enter a valid non-negative $label.');
    }
    return (value: value, error: null);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final categoryNames = _categories
        .map((category) => category.name)
        .toList(growable: false);
    final selectedCategory = _categories
        .where((category) => category.id == _categoryId)
        .firstOrNull
        ?.name;
    final selectedUnit = _units
        .where((unit) => unit.id == _unitId)
        .firstOrNull
        ?.label;
    final unitLabels = _units.map((unit) => unit.label).toList(growable: false);
    final locationLabels = _locations
        .map((location) => location.name)
        .toList(growable: false);
    final selectedLocation = _locations
        .where((location) => location.id == _locationId)
        .firstOrNull
        ?.name;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            InventoryItemHeader(
              title: _isEdit ? 'Edit Item' : 'Add Item',
              onBack: _onCancel,
              onSave: _onSubmit,
              isSaving:
                  _isSaving ||
                  _isLoadingCategories ||
                  _isLoadingUnits ||
                  _isLoadingLocations ||
                  _categoryLoadError != null ||
                  _unitLoadError != null ||
                  _locationLoadError != null,
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    if (_categoryLoadError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.dangerContainer,
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_categoryLoadError!),
                            TextButton(
                              onPressed: _loadCategories,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    if (_isLoadingCategories)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: LinearProgressIndicator(),
                      ),
                    if (_unitLoadError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.dangerContainer,
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_unitLoadError!),
                            TextButton(
                              onPressed: _loadUnits,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    if (_isLoadingUnits)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: LinearProgressIndicator(),
                      ),
                    if (_locationLoadError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.dangerContainer,
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_locationLoadError!),
                            TextButton(
                              onPressed: _loadLocations,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    if (_isLoadingLocations)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: LinearProgressIndicator(),
                      ),
                    ItemInformationCard(
                      skuController: _skuController,
                      nameController: _nameController,
                      categories: categoryNames,
                      units: unitLabels,
                      selectedCategory: selectedCategory,
                      selectedUnit: selectedUnit,
                      onCategoryChanged: (name) => setState(() {
                        _categoryId = _categories
                            .where((category) => category.name == name)
                            .firstOrNull
                            ?.id;
                      }),
                      onUnitChanged: (label) => setState(() {
                        _unitId = _units
                            .where((unit) => unit.label == label)
                            .firstOrNull
                            ?.id;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    StockInformationCard(
                      quantityController: _quantityController,
                      minStockController: _minStockController,
                      unitPriceController: _unitPriceController,
                      unitSuffix: _unitShort,
                      priceSuffix: _priceSuffix,
                      locations: locationLabels,
                      selectedLocation: selectedLocation,
                      onLocationChanged: (name) => setState(() {
                        _locationId = _locations
                            .where((location) => location.name == name)
                            .firstOrNull
                            ?.id;
                      }),
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
              isSubmitting:
                  _isSaving ||
                  _isLoadingCategories ||
                  _isLoadingUnits ||
                  _isLoadingLocations ||
                  _categoryLoadError != null ||
                  _unitLoadError != null ||
                  _locationLoadError != null,
            ),
          ],
        ),
      ),
    );
  }
}
