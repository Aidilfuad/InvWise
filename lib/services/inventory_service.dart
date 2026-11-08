import 'package:supabase_flutter/supabase_flutter.dart';

import 'activity_log_service.dart';
import 'offline_cache_service.dart';

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
    this.description,
    this.notes,
    this.location,
    this.warehouse,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  final String id;
  final String sku;
  final String name;
  final String? categoryId;
  final String? categoryName;
  final String? description;
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
  final String? createdBy;
  final DateTime? createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;

  String get unit => '$unitName ($unitAbbreviation)';
  String get unitLabel => unitAbbreviation.toUpperCase();
  String get quantityLabel => '${_formatQuantity(quantity)} $unitLabel';
  double get inventoryValue => quantity * unitPrice;

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
      description: map['description'] as String?,
      notes: map['notes'] as String?,
      location: locationName,
      warehouse: null,
      createdBy: map['created_by'] as String?,
      createdAt: _dateTimeValue(map['created_at']),
      updatedBy: map['updated_by'] as String?,
      updatedAt: _dateTimeValue(map['updated_at']),
    );
  }

  factory InventoryItem.fromCacheMap(Map<String, dynamic> map) => InventoryItem(
    id: _requiredString(map, 'id'),
    sku: _requiredString(map, 'sku'),
    name: _requiredString(map, 'name'),
    categoryId: map['categoryId'] as String?,
    categoryName: map['categoryName'] as String?,
    description: map['description'] as String?,
    unitId: _requiredString(map, 'unitId'),
    unitName: _requiredString(map, 'unitName'),
    unitAbbreviation: _requiredString(map, 'unitAbbreviation'),
    quantity: _doubleValue(map['quantity']),
    locationQuantity: _doubleValue(map['locationQuantity']),
    locationId: map['locationId'] as String?,
    minStock: _doubleValue(map['minStock']),
    unitPrice: _doubleValue(map['unitPrice']),
    notes: map['notes'] as String?,
    location: map['location'] as String?,
    warehouse: map['warehouse'] as String?,
    createdBy: map['createdBy'] as String?,
    createdAt: _dateTimeValue(map['createdAt']),
    updatedBy: map['updatedBy'] as String?,
    updatedAt: _dateTimeValue(map['updatedAt']),
  );

  Map<String, dynamic> toCacheMap() => {
    'id': id,
    'sku': sku,
    'name': name,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'description': description,
    'unitId': unitId,
    'unitName': unitName,
    'unitAbbreviation': unitAbbreviation,
    'quantity': quantity,
    'locationQuantity': locationQuantity,
    'locationId': locationId,
    'minStock': minStock,
    'unitPrice': unitPrice,
    'notes': notes,
    'location': location,
    'warehouse': warehouse,
    'createdBy': createdBy,
    'createdAt': createdAt?.toIso8601String(),
    'updatedBy': updatedBy,
    'updatedAt': updatedAt?.toIso8601String(),
  };
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
  List<InventoryItem>? _cachedItems;

  List<InventoryItem>? get cachedItems => _cachedItems;

  Future<List<InventoryItem>?> readCachedItems() async {
    final rows = await OfflineCacheService.instance.readList('inventory.items');
    if (rows == null) return null;
    return rows.map(InventoryItem.fromCacheMap).toList(growable: false);
  }

  static Future<void> invalidateItemsCache() =>
      OfflineCacheService.instance.remove('inventory.items');

  Future<List<InventoryLocation>> getLocations() =>
      OfflineCacheService.instance.loadList(
        key: 'warehouse.locations.simple',
        decode: InventoryLocation.fromMap,
        encode: (location) => {'id': location.id, 'name': location.name},
        fetchRemote: _fetchLocations,
      );

  Future<List<InventoryLocation>> _fetchLocations() async {
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

  Future<Map<String, Map<String, double>>> getStockLevelsForItems(
    List<String> itemIds,
  ) async {
    final ids = _validatedIds(itemIds);
    try {
      final rows = await _client
          .from(_stockLevelsTable)
          .select('item_id,location_id,quantity')
          .inFilter('item_id', ids);
      final levels = <String, Map<String, double>>{};
      for (final row in rows) {
        final itemId = _requiredString(row, 'item_id');
        final locationId = _requiredString(row, 'location_id');
        levels.putIfAbsent(itemId, () => {})[locationId] = _doubleValue(
          row['quantity'],
        );
      }
      return levels;
    } on PostgrestException catch (e) {
      throw InventoryServiceException(
        _friendlyMessage(e, 'load selected stock levels'),
      );
    } catch (e) {
      if (e is InventoryServiceException) rethrow;
      throw const InventoryServiceException(
        'Unable to load selected stock levels. Please try again.',
      );
    }
  }

  Future<void> setEmptyStockLocation({
    required String itemId,
    required String locationId,
  }) async {
    final id = _validatedId(itemId);
    final location = _validatedId(locationId);
    try {
      final levels = await getStockLevelsForItems([id]);
      final total = levels[id]?.values.fold<double>(
        0,
        (sum, quantity) => sum + quantity,
      );
      if (total != null && total > 0) {
        throw const InventoryServiceException(
          'Stock changed while moving the item. Refresh inventory and try '
          'again.',
        );
      }
      await _client
          .from(_stockLevelsTable)
          .delete()
          .eq('item_id', id)
          .lte('quantity', 0);
      await _client.from(_stockLevelsTable).upsert({
        'item_id': id,
        'location_id': location,
        'quantity': 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'item_id,location_id');
      await invalidateItemsCache();
    } on PostgrestException catch (e) {
      throw InventoryServiceException(
        _friendlyMessage(e, 'assign the empty item to the warehouse'),
      );
    } on InventoryServiceException {
      rethrow;
    } catch (e) {
      if (e is InventoryServiceException) rethrow;
      throw const InventoryServiceException(
        'Unable to assign the empty item to the warehouse. Please try again.',
      );
    }
  }

  Future<Map<String, String>> changeCategoryForItems(
    List<String> itemIds,
    String? categoryId,
  ) async {
    final ids = _validatedIds(itemIds);
    final category = categoryId == null ? null : _validatedId(categoryId);
    final failures = <String, String>{};
    for (final id in ids) {
      try {
        final rows = await _client
            .from(_table)
            .update({
              'category_id': category,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', id)
            .eq('is_active', true)
            .select('id');
        if (rows.isEmpty) {
          throw const InventoryServiceException(
            'Item could not be updated. Refresh inventory and try again.',
          );
        }
        await _recordActivity(
          type: ActivityEventType.inventoryUpdated,
          description: 'Changed the category for inventory item $id.',
          itemId: id,
          details: {'bulk_action': 'change_category', 'category_id': category},
        );
        await invalidateItemsCache();
        await _invalidateCategoryCaches();
      } on PostgrestException catch (error) {
        failures[id] = _friendlyMessage(
          error,
          'change the category for this item',
        );
      } on InventoryServiceException catch (error) {
        failures[id] = error.message;
      } catch (_) {
        failures[id] = 'Unable to change this item category. Please try again.';
      }
    }
    return failures;
  }

  Future<Map<String, String>> archiveItems(List<String> itemIds) async {
    final ids = _validatedIds(itemIds);
    final failures = <String, String>{};
    for (final id in ids) {
      try {
        final rows = await _client
            .from(_table)
            .update({
              'is_active': false,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', id)
            .eq('is_active', true)
            .select('id');
        if (rows.isEmpty) {
          throw const InventoryServiceException(
            'Item could not be archived. Refresh inventory and try again.',
          );
        }
        await _recordActivity(
          type: ActivityEventType.inventoryUpdated,
          description: 'Archived inventory item $id.',
          itemId: id,
          details: {'bulk_action': 'archive'},
        );
        await invalidateItemsCache();
        await _invalidateCategoryCaches();
      } on PostgrestException catch (error) {
        failures[id] = _friendlyMessage(error, 'archive this item');
      } on InventoryServiceException catch (error) {
        failures[id] = error.message;
      } catch (_) {
        failures[id] = 'Unable to archive this item. Please try again.';
      }
    }
    return failures;
  }

  Future<Map<String, String>> deleteItemsPermanently(
    List<String> itemIds,
  ) async {
    final ids = _validatedIds(itemIds);
    final failures = <String, String>{};
    for (final id in ids) {
      try {
        final rows = await _client
            .from(_table)
            .delete()
            .eq('id', id)
            .select('id');
        if (rows.isEmpty) {
          throw const InventoryServiceException(
            'Item could not be deleted. Refresh inventory and try again.',
          );
        }
        await invalidateItemsCache();
        await _invalidateCategoryCaches();
      } on PostgrestException catch (error) {
        failures[id] = error.code == '23503'
            ? 'Item is referenced by stock or activity history and cannot be '
                  'permanently deleted. Archive it instead.'
            : _friendlyMessage(error, 'permanently delete this item');
      } on InventoryServiceException catch (error) {
        failures[id] = error.message;
      } catch (_) {
        failures[id] =
            'Unable to permanently delete this item. Please try again.';
      }
    }
    return failures;
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
      await invalidateItemsCache();
      await _invalidateWarehouseCaches();
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

  Future<List<InventoryItem>> getItems({bool forceRefresh = false}) async {
    final items = await OfflineCacheService.instance.loadList(
      key: 'inventory.items',
      decode: InventoryItem.fromCacheMap,
      encode: (item) => item.toCacheMap(),
      fetchRemote: _fetchItems,
      forceRefresh: forceRefresh,
    );
    _cachedItems = items;
    return items;
  }

  Future<List<InventoryItem>> _fetchItems() async {
    try {
      final rows = await _client
          .from(_table)
          .select(_selectColumns)
          .eq('is_active', true)
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

  Future<void> _invalidateCategoryCaches() async {
    await OfflineCacheService.instance.remove('categories.active');
    await OfflineCacheService.instance.remove('categories.all');
  }

  Future<void> _invalidateWarehouseCaches() async {
    await OfflineCacheService.instance.remove('warehouses.active');
    await OfflineCacheService.instance.remove('warehouses.all');
  }

  Future<InventoryItem> getItemById(String id) async {
    final itemId = _validatedId(id);
    try {
      final row = await _client
          .from(_table)
          .select(_selectColumns)
          .eq('id', itemId)
          .eq('is_active', true)
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
      await invalidateItemsCache();
      await _invalidateCategoryCaches();
      await _invalidateWarehouseCaches();
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
      await invalidateItemsCache();
      await _invalidateCategoryCaches();
      await _invalidateWarehouseCaches();
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
      final rows = await _client
          .from(_table)
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', itemId)
          .eq('is_active', true)
          .select('id');
      if (rows.isEmpty) {
        throw const InventoryServiceException(
          'Item not found, or you do not have permission to delete it.',
        );
      }
      await _recordActivity(
        type: ActivityEventType.inventoryDeleted,
        description:
            'Archived inventory item ${item['name']} (SKU ${item['sku']}).',
        details: {
          'deleted_item_id': itemId,
          'item_name': item['name'],
          'sku': item['sku'],
        },
      );
      await invalidateItemsCache();
      await _invalidateCategoryCaches();
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
    final positiveLocations = <String, String>{};
    final fallbackLocations = <String, String>{};
    final quantitiesByLocation = <String, Map<String, double>>{};
    for (final stock in stockRows) {
      final itemId = stock['item_id'] as String;
      final locationId = stock['location_id'] as String;
      final quantity = _doubleValue(stock['quantity']);
      locationIds.add(locationId);
      fallbackLocations.putIfAbsent(itemId, () => locationId);
      if (quantity > 0) positiveLocations.putIfAbsent(itemId, () => locationId);
      quantities.update(
        itemId,
        (total) => total + quantity,
        ifAbsent: () => quantity,
      );
      quantitiesByLocation.putIfAbsent(itemId, () => {})[locationId] = quantity;
    }
    final itemLocations = <String, String>{};
    for (final itemId in itemIds) {
      final locationId = positiveLocations[itemId] ?? fallbackLocations[itemId];
      if (locationId != null) itemLocations[itemId] = locationId;
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
            locationQuantity:
                quantitiesByLocation[row['id']
                    as String]?[itemLocations[row['id'] as String]] ??
                0,
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

  List<String> _validatedIds(List<String> ids) {
    final normalized = ids.map((id) => id.trim()).toSet().toList();
    if (normalized.isEmpty || normalized.any((id) => id.isEmpty)) {
      throw const InventoryServiceException(
        'Select at least one valid inventory item.',
      );
    }
    return normalized;
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

DateTime? _dateTimeValue(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _formatQuantity(double value) =>
    value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
