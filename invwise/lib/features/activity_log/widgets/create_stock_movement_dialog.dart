import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../services/inventory_service.dart';
import '../../../services/stock_movement_service.dart';
import '../../../widgets/searchable_dropdown_form_field.dart';

class CreateStockMovementDialog extends StatefulWidget {
  const CreateStockMovementDialog({
    super.key,
    required this.items,
    required this.locations,
    required this.onSave,
  });

  final List<InventoryItem> items;
  final List<InventoryLocation> locations;
  final Future<void> Function({
    required String itemId,
    required StockMovementType type,
    required double quantity,
    String? sourceLocationId,
    String? destinationLocationId,
    String? reference,
    String? notes,
  })
  onSave;

  @override
  State<CreateStockMovementDialog> createState() =>
      _CreateStockMovementDialogState();
}

class _CreateStockMovementDialogState extends State<CreateStockMovementDialog> {
  final _quantityController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  StockMovementType _type = StockMovementType.receipt;
  String? _itemId;
  String? _sourceLocationId;
  String? _destinationLocationId;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _itemId = widget.items.firstOrNull?.id;
    _sourceLocationId = widget.locations.firstOrNull?.id;
    _destinationLocationId = widget.locations
        .where((location) => location.id != _sourceLocationId)
        .firstOrNull
        ?.id;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final itemId = _itemId;
    final quantity = double.tryParse(_quantityController.text.trim());
    if (itemId == null) {
      setState(() => _errorMessage = 'Select an inventory item.');
      return;
    }
    if (quantity == null || !quantity.isFinite || quantity <= 0) {
      setState(() => _errorMessage = 'Enter a quantity greater than zero.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.onSave(
        itemId: itemId,
        type: _type,
        quantity: quantity,
        sourceLocationId: _sourceLocationId,
        destinationLocationId: _destinationLocationId,
        reference: _referenceController.text,
        notes: _notesController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst(
          'StockMovementServiceException: ',
          '',
        );
        _isSaving = false;
      });
    }
  }

  void _onTypeChanged(StockMovementType? type) {
    if (type == null) return;
    setState(() {
      _type = type;
      _errorMessage = null;
      if (type == StockMovementType.transfer &&
          _sourceLocationId == _destinationLocationId) {
        _destinationLocationId = widget.locations
            .where((location) => location.id != _sourceLocationId)
            .firstOrNull
            ?.id;
      }
    });
  }

  void _onSourceLocationChanged(String? locationId) {
    setState(() {
      _sourceLocationId = locationId;
      _errorMessage = null;
      if (_type == StockMovementType.transfer &&
          locationId == _destinationLocationId) {
        _destinationLocationId = widget.locations
            .where((location) => location.id != locationId)
            .firstOrNull
            ?.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create Stock Movement'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchableDropdownFormField(
              initialValue: _type.name,
              decoration: const InputDecoration(labelText: 'Movement type'),
              options: StockMovementType.values
                  .map((type) => type.name)
                  .toList(),
              optionLabels: {
                for (final type in StockMovementType.values)
                  type.name: type.label,
              },
              enabled: !_isSaving,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) return;
                      _onTypeChanged(
                        StockMovementType.values.firstWhere(
                          (type) => type.name == value,
                        ),
                      );
                    },
            ),
            const SizedBox(height: 12),
            SearchableDropdownFormField(
              initialValue: _itemId,
              decoration: const InputDecoration(labelText: 'Inventory item'),
              options: widget.items.map((item) => item.id).toList(),
              optionLabels: {
                for (final item in widget.items)
                  item.id: '${item.name} · ${item.sku}',
              },
              enabled: !_isSaving,
              onChanged: _isSaving
                  ? null
                  : (itemId) => setState(() => _itemId = itemId),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: 'Enter quantity',
              ),
            ),
            if (_type == StockMovementType.issue ||
                _type == StockMovementType.transfer) ...[
              const SizedBox(height: 12),
              _locationSelector(
                label: 'Source location',
                value: _sourceLocationId,
                onChanged: _onSourceLocationChanged,
              ),
            ],
            if (_type == StockMovementType.receipt ||
                _type == StockMovementType.transfer ||
                _type == StockMovementType.returnItem) ...[
              const SizedBox(height: 12),
              _locationSelector(
                label: 'Destination location',
                value: _destinationLocationId,
                availableLocations: _type == StockMovementType.transfer
                    ? widget.locations
                          .where((location) => location.id != _sourceLocationId)
                          .toList(growable: false)
                    : widget.locations,
                onChanged: (id) {
                  setState(() {
                    _destinationLocationId = id;
                    _errorMessage = null;
                  });
                },
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _isSaving ? null : _save,
        child: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save'),
      ),
    ],
  );

  Widget _locationSelector({
    required String label,
    required String? value,
    List<InventoryLocation>? availableLocations,
    required ValueChanged<String?> onChanged,
  }) {
    final locations = availableLocations ?? widget.locations;
    final selectedValue = locations.any((location) => location.id == value)
        ? value
        : null;
    return SearchableDropdownFormField(
      initialValue: selectedValue,
      decoration: InputDecoration(labelText: label),
      options: locations.map((location) => location.id).toList(),
      optionLabels: {
        for (final location in locations) location.id: location.name,
      },
      enabled: !_isSaving,
      onChanged: onChanged,
    );
  }
}
