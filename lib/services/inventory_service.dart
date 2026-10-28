import 'package:supabase_flutter/supabase_flutter.dart';

import 'activity_log_service.dart';

class InventoryServiceException implements Exception {
  const InventoryServiceException(this.message);

  final String message;

  @override
  String toString() => 'InventoryServiceException: $message';
}

class InventoryLocation {
  const InventoryLocation({required this.id, required this.name});

  final String id;
  final String name;

  factory InventoryLocation.fromMap(Map<String, dynamic> map) =>
      InventoryLocation(
        id: _requiredString(map, 'id'),
        name: _requiredString(map, 'name'),
      );
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.unitId,
    required this.unitName,
    required this.unitAbbreviation,
    required this.quantity,
    required this.locationQuantity,
    required this.locationId,
    required this.minStock,
    required this.unitPrice,
    this.categoryId,
    this.categoryName,
    this.notes,
    this.location,
    this.warehouse,
  });

  final String id;
  final String sku;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final String unitId;
  final String unitName;
  final String unitAbbreviation;
  final double quantity;
  final double locationQuantity;
  final String? locationId;
  final double minStock;
  final double unitPrice;
  final String? notes;
  final String? location;
  final String? warehouse;

  String get unit => '$unitName ($unitAbbreviation)';
  String get unitLabel => unitAbbreviation.toUpperCase();
  String get quantityLabel => '${_formatQuantity(quantity)} $unitLabel';

  InventoryStockStatus get status {
    if (quantity <= 0) return InventoryStockStatus.outOfStock;
    if (quantity <= minStock) return InventoryStockStatus.lowStock;
    return InventoryStockStatus.inStock;
  }

  static InventoryItem fromMap(
    Map<String, dynamic> map, {
    double quantity = 0,
    double locationQuantity = 0,
    String? locationId,
    String? locationName,
  }) {
    final category = map['category'];
    final unit = map['unit'];
    String? categoryName;
    if (category is Map) {
      categoryName = category['name'] as String?;
    } else if (category is List && category.isNotEmpty) {
      final first = category.first;
      if (first is Map) categoryName = first['name'] as String?;
    }
    if (unit is! Map) {
      throw const FormatException('Inventory item is missing its unit.');
    }

    return InventoryItem(
      id: _requiredString(map, 'id'),
      sku: _requiredString(map, 'sku'),
      name: _requiredString(map, 'name'),
      categoryId: map['category_id'] as String?,
      categoryName: categoryName,
      unitId: _requiredString(map, 'unit_id'),
      unitName: _requiredString(unit, 'name'),
      unitAbbreviation: _requiredString(unit, 'abbreviation'),
      quantity: quantity,
      locationQuantity: locationQuantity,
      locationId: locationId,
      minStock: _doubleValue(map['minimum_stock']),
      unitPrice: _doubleValue(map['unit_price']),
      notes: map['notes'] as String?,
      location: locationName,
      warehouse: null,
    );
  }
}

enum InventoryStockStatus {
  inStock('In Stock'),
  lowStock('Low Stock'),
  outOfStock('Out of Stock');

  const InventoryStockStatus(this.label);

  final String label;
}

class InventoryService {
  InventoryService();

  final SupabaseClient _client = Supabase.instance.client;
  final ActivityLogService _activityLogService = ActivityLogService();

  String? lastActivityLogWarning;

  static const String _table = 'inventory_items';
  static const String _locationsTable = 'warehouse_locations';
  static const String _stockLevelsTable = 'stock_levels';
  static const String _selectColumns =
      '*, category:categories(name), unit:units(name,abbreviation)';

  Future<List<InventoryLocation>> getLocations() async {
    try {
      final rows = await _client
          .from(_locationsTable)
          .select('id,name')
          .order('name', ascending: true);
      return rows
          .map<InventoryLocation>(InventoryLocation.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw InventoryServiceException(
        _friendlyMessage(e, 'load warehouse locations'),
      );
    } catch (e) {
      if (e is InventoryServiceException) rethrow;
      throw const InventoryServiceException(
        'Unable to load warehouse locations. Please check your connection and '
        'try again.',
      );
    }
  }

  Future<double> getStockQuantity({
    required String itemId,
    required String locationId,
  }) async {
    try {
      final row = await _client
          .from(_stockLevelsTable)
          .select('quantity')
          .eq('item_id', _validatedId(itemId))
          .eq('location_id', _validatedId(locationId))
          .maybeSingle();
      return row == null ? 0 : _doubleValue(row['quantity']);
    } on PostgrestException catch (e) {
      throw InventoryServiceException(
        _friendlyMessage(e, 'load the stock quantity'),
      );
    } on InventoryServiceException {
      rethrow;
    } catch (e) {
      throw const InventoryServiceException(
        'Unable to load the stock quantity. Please try again.',
      );
    }
  }

  Future<double> adjustStock({
    required String itemId,
    required String locationId,
    required double quantity,
    required bool add,
  }) async {
    lastActivityLogWarning = null;
    final validatedItemId = _validatedId(itemId);
    final validatedLocationId = _validatedId(locationId);
    if (!quantity.isFinite || quantity <= 0) {
      throw const InventoryServiceException(
        'Enter a stock adjustment greater than zero.',
      );
    }

    try {
      final currentQuantity = await getStockQuantity(
        itemId: validatedItemId,
        locationId: validatedLocationId,
      );
      final updatedQuantity = add
          ? currentQuantity + quantity
          : currentQuantity - quantity;
      if (updatedQuantity < 0) {
        throw const InventoryServiceException(
          'Cannot remove more stock than is available at this location.',
        );
      }

      await _client.from(_stockLevelsTable).upsert({
        'item_id': validatedItemId,
        'location_id': validatedLocationId,
        'quantity': updatedQuantity,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'item_id,location_id');
      await _recordActivity(
        type: ActivityEventType.stockAdjustment,
        description:
            '${add ? 'Added' : 'Removed'} $quantity units for inventory item '
            '$validatedItemId.',
        itemId: validatedItemId,
        locationId: validatedLocationId,
        details: {
          'quantity': quantity,
          'operation': add ? 'add' : 'remove',
          'previous_quantity': currentQuantity,
          'updated_quantity': updatedQuantity,
        },
      );
      return updatedQuantity;
    } on PostgrestException catch (e) {
      throw InventoryServiceException(
        _friendlyMessage(e, 'save the stock adjustment'),
      );
    } on InventoryServiceException {
      rethrow;
    } catch (e) {
      throw const InventoryServiceException(
        'Unable to save the stock adjustment. Please try again.',
      );
    }
  }

  Future<List<InventoryItem>> getItems() async {
    try {
      final rows = await _client
          .from(_table)
          .select(_selectColumns)
          .order('name', ascending: true);
      return await _withQuantities(rows);
    } on PostgrestException catch (e) {
      throw InventoryServiceException(_friendlyMessage(e, 'load inventory'));
    } catch (e) {
      if (e is InventoryServiceException) rethrow;
      throw const InventoryServiceException(
        'Unable to load inventory. Please check your connection and try again.',
      );
    }
  }

  Future<InventoryItem> getItemById(String id) async {
    final itemId = _validatedId(id);
    try {
      final row = await _client
          .from(_table)
          .select(_selectColumns)
          .eq('id', itemId)
          .maybeSingle();
      if (row == null) {
        throw const InventoryServiceException('Inventory item not found.');
      }
      return (await _withQuantities([row])).single;
    } on PostgrestException catch (e) {
      throw InventoryServiceException(_friendlyMessage(e, 'load the item'));
    } catch (e) {
      if (e is InventoryServiceException) rethrow;
      throw const InventoryServiceException(
        'Unable to load the item. Please check your connection and try again.',
      );
    }
  }

  Future<InventoryItem> createItem({
    required String sku,
    required String name,
    required String? categoryId,
    required String unitId,
    required String locationId,
    required double quantity,
    required double minStock,
    required double unitPrice,
    String? notes,
  }) async {
    lastActivityLogWarning = null;
    final payload = _validatedPayload(
      sku: sku,
      name: name,
      categoryId: categoryId,
      unitId: unitId,
      locationId: locationId,
      quantity: quantity,
      minStock: minStock,
      unitPrice: unitPrice,
      notes: notes,
    );

    try {
      // These are inventory_items columns only. Quantity belongs to stock_levels.
      final inserted = await _client
          .from(_table)
          .insert(payload)
          .select('id')
          .single();
      final itemId = inserted['id'] as String;

      try {
        await _client.from(_stockLevelsTable).insert({
          'item_id': itemId,
          'location_id': locationId,
          'quantity': quantity,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } on PostgrestException catch (e) {
        try {
          await _client.from(_table).delete().eq('id', itemId);
        } on PostgrestException catch (rollbackError) {
          throw InventoryServiceException(
            'The item was created, but initial stock could not be saved '
            '(${e.message}); cleanup also failed (${rollbackError.message}).',
          );
        }
        throw InventoryServiceException(
          _friendlyMessage(e, 'save the initial stock quantity'),
        );
      }

      final item = await getItemById(itemId);
      await _recordActivity(
        type: ActivityEventType.inventoryCreated,
        description: 'Created inventory item ${item.name} (SKU ${item.sku}).',
        itemId: item.id,
        locationId: locationId,
        details: {
          'sku': item.sku,
          'item_name': item.name,
          'initial_quantity': quantity,
        },
      );
      return item;
    } on PostgrestException catch (e) {
      throw InventoryServiceException(_friendlyMessage(e, 'create the item'));
    } on InventoryServiceException {
      rethrow;
    } catch (e) {
      if (e is InventoryServiceException) rethrow;
      throw const InventoryServiceException(
        'Unable to create the item. Please check your connection and try again.',
      );
    }
  }

  Future<InventoryItem> updateItem({
    required String id,
    required String sku,
    required String name,
    required String? categoryId,
    required String unitId,
    required String locationId,
    required double quantity,
    required double minStock,
    required double unitPrice,
    String? notes,
  }) async {
    lastActivityLogWarning = null;
    final itemId = _validatedId(id);
    final payload = _validatedPayload(
      sku: sku,
      name: name,
      categoryId: categoryId,
      unitId: unitId,
      locationId: locationId,
      quantity: quantity,
      minStock: minStock,
      unitPrice: unitPrice,
      notes: notes,
    )..remove('is_active');
    payload['updated_at'] = DateTime.now().toUtc().toIso8601String();

    try {
      final row = await _client
          .from(_table)
          .update(payload)
          .eq('id', itemId)
          .select('id')
          .maybeSingle();
      if (row == null) {
        throw const InventoryServiceException(
          'Item not found, or you do not have permission to update it.',
        );
      }

      await _client.from(_stockLevelsTable).upsert({
        'item_id': itemId,
        'location_id': locationId,
        'quantity': quantity,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'item_id,location_id');
      final item = await getItemById(itemId);
      await _recordActivity(
        type: ActivityEventType.inventoryUpdated,
        description: 'Updated inventory item ${item.name} (SKU ${item.sku}).',
        itemId: item.id,
        locationId: locationId,
        details: {
          'sku': item.sku,
          'item_name': item.name,
          'quantity': quantity,
        },
      );
      return item;
    } on PostgrestException catch (e) {
      throw InventoryServiceException(_friendlyMessage(e, 'update the item'));
    } on InventoryServiceException {
      rethrow;
    } catch (e) {
      if (e is InventoryServiceException) rethrow;
      throw const InventoryServiceException(
        'Unable to update the item. Please check your connection and try again.',
      );
    }
  }

  Future<void> deleteItem(String id) async {
    lastActivityLogWarning = null;
    final itemId = _validatedId(id);
    try {
      final item = await _client
          .from(_table)
          .select('name,sku')
          .eq('id', itemId)
          .maybeSingle();
      if (item == null) {
        throw const InventoryServiceException('Inventory item not found.');
      }
      await _client.from(_stockLevelsTable).delete().eq('item_id', itemId);
      final rows = await _client
          .from(_table)
          .delete()
          .eq('id', itemId)
          .select('id');
      if (rows.isEmpty) {
        throw const InventoryServiceException(
          'Item not found, or you do not have permission to delete it.',
        );
      }
      await _recordActivity(
        type: ActivityEventType.inventoryDeleted,
        description:
            'Deleted inventory item ${item['name']} (SKU ${item['sku']}).',
        details: {
          'deleted_item_id': itemId,
          'item_name': item['name'],
          'sku': item['sku'],
        },
      );
    } on PostgrestException catch (e) {
      throw InventoryServiceException(_friendlyMessage(e, 'delete the item'));
    } on InventoryServiceException {
      rethrow;
    } catch (e) {
      if (e is InventoryServiceException) rethrow;
      throw const InventoryServiceException(
        'Unable to delete the item. Please check your connection and try again.',
      );
    }
  }

  Future<void> _recordActivity({
    required ActivityEventType type,
    required String description,
    String? itemId,
    String? locationId,
    Map<String, dynamic> details = const {},
  }) async {
    try {
      await _activityLogService.recordEvent(
        type: type,
        description: description,
        itemId: itemId,
        locationId: locationId,
        details: details,
      );
    } on ActivityLogServiceException catch (error) {
      lastActivityLogWarning =
          'The inventory change succeeded, but activity logging failed: '
          '${error.message}';
      reportActivityLogFailure(error);
    }
  }

  Map<String, dynamic> _validatedPayload({
    required String sku,
    required String name,
    required String? categoryId,
    required String unitId,
    required String locationId,
    required double quantity,
    required double minStock,
    required double unitPrice,
    required String? notes,
  }) {
    final cleanedSku = sku.trim();
    final cleanedName = name.trim();
    final cleanedUnitId = unitId.trim();
    if (cleanedSku.isEmpty ||
        cleanedName.isEmpty ||
        cleanedUnitId.isEmpty ||
        locationId.trim().isEmpty) {
      throw const InventoryServiceException(
        'Please enter an SKU and item name, and select a unit and location.',
      );
    }
    if (!quantity.isFinite ||
        quantity < 0 ||
        !minStock.isFinite ||
        minStock < 0 ||
        !unitPrice.isFinite ||
        unitPrice < 0) {
      throw const InventoryServiceException(
        'Quantity, minimum stock, and unit price must be zero or greater.',
      );
    }

    final cleanedNotes = notes?.trim();
    return {
      'sku': cleanedSku,
      'name': cleanedName,
      'description': null,
      'category_id': categoryId,
      'unit_id': cleanedUnitId,
      'minimum_stock': minStock,
      'unit_price': unitPrice,
      'notes': cleanedNotes == null || cleanedNotes.isEmpty
          ? null
          : cleanedNotes,
      'is_active': true,
    };
  }

  Future<List<InventoryItem>> _withQuantities(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return const [];
    final itemIds = rows.map((row) => row['id'] as String).toList();
    final stockRows = await _client
        .from(_stockLevelsTable)
        .select('item_id,location_id,quantity')
        .inFilter('item_id', itemIds)
        .order('location_id', ascending: true);
    final quantities = <String, double>{};
    final locationIds = <String>{};
    final itemLocations = <String, String>{};
    final locationQuantities = <String, double>{};
    for (final stock in stockRows) {
      final itemId = stock['item_id'] as String;
      final locationId = stock['location_id'] as String;
      final quantity = _doubleValue(stock['quantity']);
      locationIds.add(locationId);
      itemLocations.putIfAbsent(itemId, () => locationId);
      quantities.update(
        itemId,
        (total) => total + quantity,
        ifAbsent: () => quantity,
      );
      if (itemLocations[itemId] == locationId) {
        locationQuantities[itemId] = quantity;
      }
    }
    final List<Map<String, dynamic>> locations = locationIds.isEmpty
        ? const []
        : await _client
              .from(_locationsTable)
              .select('id,name')
              .inFilter('id', locationIds.toList());
    final locationNames = {
      for (final location in locations)
        location['id'] as String: location['name'] as String,
    };
    return rows
        .map<InventoryItem>(
          (row) => InventoryItem.fromMap(
            row,
            quantity: quantities[row['id'] as String] ?? 0,
            locationQuantity: locationQuantities[row['id'] as String] ?? 0,
            locationId: itemLocations[row['id'] as String],
            locationName: locationNames[itemLocations[row['id'] as String]],
          ),
        )
        .toList(growable: false);
  }

  String _validatedId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw const InventoryServiceException('Inventory item not found.');
    }
    return trimmed;
  }

  String _friendlyMessage(PostgrestException e, String action) {
    final message = e.message.toLowerCase();
    if (e.code == '23505') {
      return 'An inventory item with this SKU already exists.';
    }
    if (e.code == '23503') {
      return 'The selected category or unit is no longer available.';
    }
    if (e.code == '23502') {
      return 'Please fill in all required fields.';
    }
    if (e.code == '42501' || message.contains('row-level security')) {
      return 'You do not have permission to $action.';
    }
    if (message.contains('jwt') || e.code == 'PGRST301') {
      return 'Your session has expired. Please sign in again.';
    }
    return 'Unable to $action. ${e.message}';
  }
}

String _requiredString(Map map, String key) {
  final value = map[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('Database row is missing required field "$key".');
}

double _doubleValue(Object? value) {
  if (value is num && value.isFinite) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed.isFinite) return parsed;
  }
  throw const FormatException('Inventory item contains an invalid number.');
}

String _formatQuantity(double value) =>
    value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
