/// Mock data for the Inventory Item page (Add / Edit).
/// UI-only. No backend or Supabase logic.

enum InventoryItemMode { create, edit }

class InventoryItemFormData {
  const InventoryItemFormData({
    this.sku = '',
    this.name = '',
    this.category,
    this.unit,
    this.quantity = '',
    this.minStock = '',
    this.unitPrice = '',
    this.notes = '',
  });

  final String sku;
  final String name;
  final String? category;
  final String? unit;
  final String quantity;
  final String minStock;
  final String unitPrice;
  final String notes;
}

class InventoryItemMockData {
  const InventoryItemMockData._();

  static const List<String> categories = [
    'Fasteners',
    'Electrical',
    'Plumbing',
    'Tools',
    'Safety',
    'Consumables',
  ];

  static const List<String> units = [
    'Pieces (pcs)',
    'Boxes (box)',
    'Kilograms (kg)',
    'Liters (L)',
    'Meters (m)',
  ];

  /// Sample item used when the page is opened in Edit Mode.
  static const InventoryItemFormData sampleItem = InventoryItemFormData(
    sku: 'FST-0842',
    name: 'M12 Hex Bolt',
    category: 'Fasteners',
    unit: 'Pieces (pcs)',
    quantity: '240',
    minStock: '50',
    unitPrice: '0.85',
    notes: 'Zinc-plated, grade 8.8. For routine equipment maintenance.',
  );
}