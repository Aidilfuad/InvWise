import 'package:flutter_test/flutter_test.dart';
import 'package:invwise/features/inventory/inventory_page.dart';
import 'package:invwise/services/inventory_service.dart';

void main() {
  group('InventoryStockFilter', () {
    test('all stock matches every status', () {
      expect(
        InventoryStockFilter.all.matches(InventoryStockStatus.inStock),
        isTrue,
      );
      expect(
        InventoryStockFilter.all.matches(InventoryStockStatus.lowStock),
        isTrue,
      );
      expect(
        InventoryStockFilter.all.matches(InventoryStockStatus.outOfStock),
        isTrue,
      );
    });

    test('status filters only match their selected stock status', () {
      expect(
        InventoryStockFilter.inStock.matches(InventoryStockStatus.inStock),
        isTrue,
      );
      expect(
        InventoryStockFilter.inStock.matches(InventoryStockStatus.lowStock),
        isFalse,
      );
      expect(
        InventoryStockFilter.lowStock.matches(InventoryStockStatus.lowStock),
        isTrue,
      );
      expect(
        InventoryStockFilter.outOfStock.matches(
          InventoryStockStatus.outOfStock,
        ),
        isTrue,
      );
    });
  });
}
