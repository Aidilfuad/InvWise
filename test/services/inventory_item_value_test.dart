import 'package:flutter_test/flutter_test.dart';
import 'package:invwise/services/inventory_service.dart';

void main() {
  test('inventory value is current stock multiplied by unit price', () {
    const item = InventoryItem(
      id: 'item-1',
      sku: 'SKU-1',
      name: 'Sample item',
      unitId: 'unit-1',
      unitName: 'Piece',
      unitAbbreviation: 'PCS',
      quantity: 150,
      locationQuantity: 150,
      locationId: 'warehouse-1',
      minStock: 10,
      unitPrice: 1.2,
    );

    expect(item.inventoryValue, 180);
  });
}
