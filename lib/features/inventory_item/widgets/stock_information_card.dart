import 'package:flutter/material.dart';

import '../../../app/constants/app_spacing.dart';
import 'item_information_card.dart';

class StockInformationCard extends StatelessWidget {
  const StockInformationCard({
    super.key,
    required this.quantityController,
    required this.minStockController,
    required this.unitPriceController,
    required this.unitSuffix,
    required this.priceSuffix,
    required this.locations,
    required this.selectedLocation,
    required this.onLocationChanged,
  });

  final TextEditingController quantityController;
  final TextEditingController minStockController;
  final TextEditingController unitPriceController;

  /// e.g. "pcs"
  final String unitSuffix;

  /// e.g. "USD / pc"
  final String priceSuffix;
  final List<String> locations;
  final String? selectedLocation;
  final ValueChanged<String?> onLocationChanged;

  @override
  Widget build(BuildContext context) {
    return InventoryItemCardShell(
      title: 'Stock Information',
      child: Column(
        children: [
          InventoryItemField(
            label: 'Initial Quantity',
            controller: quantityController,
            hint: '0',
            suffix: unitSuffix,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: AppSpacing.md),
          InventoryItemDropdown(
            label: 'Warehouse Location',
            value: selectedLocation,
            items: locations,
            onChanged: onLocationChanged,
          ),
          SizedBox(height: AppSpacing.md),
          InventoryItemField(
            label: 'Minimum Stock Threshold',
            controller: minStockController,
            hint: '0',
            suffix: unitSuffix,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.md),
          InventoryItemField(
            label: 'Unit Price',
            controller: unitPriceController,
            hint: '0.00',
            prefix: '\$',
            suffix: priceSuffix,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }
}
