import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/dashboard/data/dashboard_data.dart';
import 'offline_cache_service.dart';
import 'stock_movement_service.dart';
import 'system_activity_log_service.dart';

class DashboardServiceException implements Exception {
  const DashboardServiceException(this.message);

  final String message;

  @override
  String toString() => 'DashboardServiceException: $message';
}

class DashboardService {
  DashboardService();

  final SupabaseClient _client = Supabase.instance.client;
  final StockMovementService _movementService = StockMovementService();
  final SystemActivityLogService _systemActivityLogService =
      SystemActivityLogService();

  Future<DashboardData> loadDashboard() =>
      OfflineCacheService.instance.loadValue(
        key: 'dashboard.data',
        decode: (value) =>
            DashboardData.fromCacheMap(Map<String, dynamic>.from(value as Map)),
        encode: (data) => data.toCacheMap(),
        fetchRemote: _fetchDashboard,
      );

  Future<DashboardData?> readCachedDashboard() async {
    final value = await OfflineCacheService.instance.readValue(
      'dashboard.data',
    );
    if (value is! Map) return null;
    return DashboardData.fromCacheMap(Map<String, dynamic>.from(value));
  }

  Future<DashboardData> _fetchDashboard() async {
    try {
      final results = await Future.wait<Object>([
        (() async => await _client
            .from('inventory_items')
            .select('id,minimum_stock,is_active,is_archived,unit_price'))(),
        (() async =>
            await _client.from('inventory_items_with_quantity').select())(),
        (() async => await _client.from('inventory_alerts').select())(),
        (() async => await _client.from('warehouse_locations').select('id'))(),
        _movementService.getMovements(limit: 3),
        _systemActivityLogService.getLatest(limit: 5),
      ]);

      final allInventoryItems = _rows(results[0]);
      final inventoryItems = allInventoryItems
          .where(
            (row) =>
                (row['is_active'] as bool? ?? true) &&
                !(row['is_archived'] as bool? ?? false),
          )
          .toList(growable: false);
      final inactiveItems = allInventoryItems
          .where(
            (row) =>
                !(row['is_active'] as bool? ?? true) &&
                !(row['is_archived'] as bool? ?? false),
          )
          .length;
      final archivedItems = allInventoryItems
          .where((row) => row['is_archived'] as bool? ?? false)
          .length;
      final quantityRows = _rows(results[1]);
      final alertRows = _rows(results[2]);
      final warehouseRows = _rows(results[3]);
      final movements = results[4] as List<StockMovement>;
      final systemActivities = results[5] as List<SystemActivityEntry>;

      final quantityByItem = <String, double>{};
      final unitPriceByItem = <String, double>{};
      final activeItemIds = inventoryItems
          .map((item) => _stringValue(item['id']))
          .whereType<String>()
          .toSet();
      var totalStockQuantity = 0.0;
      for (final item in inventoryItems) {
        final itemId = _stringValue(item['id']);
        if (itemId != null) {
          unitPriceByItem[itemId] = _numberValue(item['unit_price']);
        }
      }
      for (final row in quantityRows) {
        final itemId = _stringValue(row['item_id'] ?? row['id']);
        if (itemId == null || !activeItemIds.contains(itemId)) continue;
        final quantity = _quantityValue(row);
        totalStockQuantity += quantity;
        quantityByItem.update(
          itemId,
          (total) => total + quantity,
          ifAbsent: () => quantity,
        );
      }
      final totalAssetValue = quantityByItem.entries.fold<double>(
        0,
        (total, entry) =>
            total + entry.value * (unitPriceByItem[entry.key] ?? 0),
      );

      final minimumStockByItem = <String, double>{};
      for (final row in inventoryItems) {
        final itemId = _stringValue(row['id']);
        if (itemId != null) {
          minimumStockByItem[itemId] = _numberValue(
            row['minimum_stock'] ?? row['min_stock'] ?? row['reorder_level'],
          );
        }
      }

      final lowAlertIds = <String>{};
      final outOfStockAlertIds = <String>{};
      var hasLowAlertRows = false;
      var hasOutOfStockAlertRows = false;
      for (final alert in alertRows) {
        final type = _alertType(alert);
        final itemId = _stringValue(
          alert['item_id'] ?? alert['inventory_item_id'],
        );
        if (type.contains('out') && type.contains('stock')) {
          hasOutOfStockAlertRows = true;
          if (itemId != null) outOfStockAlertIds.add(itemId);
        } else if (type.contains('low') && type.contains('stock')) {
          hasLowAlertRows = true;
          if (itemId != null) lowAlertIds.add(itemId);
        }
      }

      var lowStockItems = 0;
      var outOfStockItems = 0;
      for (final item in inventoryItems) {
        final itemId = _stringValue(item['id']);
        if (itemId == null) continue;
        final quantity = quantityByItem[itemId] ?? 0;
        if (hasOutOfStockAlertRows) {
          if (outOfStockAlertIds.contains(itemId)) outOfStockItems++;
        } else if (quantity <= 0) {
          outOfStockItems++;
        }

        if (hasLowAlertRows) {
          if (lowAlertIds.contains(itemId) &&
              !outOfStockAlertIds.contains(itemId)) {
            lowStockItems++;
          }
        } else if (quantity > 0 &&
            quantity <= (minimumStockByItem[itemId] ?? 0)) {
          lowStockItems++;
        }
      }

      return DashboardData(
        summary: DashboardInventorySummary(
          totalItems: inventoryItems.length,
          totalStockQuantity: totalStockQuantity,
          totalAssetValue: totalAssetValue,
          lowStockItems: lowStockItems,
          outOfStockItems: outOfStockItems,
          warehouseLocations: warehouseRows.length,
          inactiveItems: inactiveItems,
          archivedItems: archivedItems,
        ),
        recentMovements: movements,
        recentActivity: const [],
        systemActivities: systemActivities,
      );
    } on PostgrestException catch (error) {
      throw DashboardServiceException(_friendlyMessage(error));
    } on StockMovementServiceException catch (error) {
      throw DashboardServiceException(error.message);
    } on DashboardServiceException {
      rethrow;
    } catch (error) {
      throw DashboardServiceException(
        'Unable to load dashboard data. Please try again. ($error)',
      );
    }
  }

  List<Map<String, dynamic>> _rows(Object? value) {
    if (value is List<Map<String, dynamic>>) return value;
    if (value is List) {
      return value
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    }
    throw const FormatException('Dashboard query returned an invalid result.');
  }

  String _alertType(Map<String, dynamic> alert) {
    for (final key in const [
      'alert_type',
      'alert_level',
      'severity',
      'alert_name',
      'alert_title',
      'type',
      'status',
    ]) {
      final value = alert[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim().toLowerCase().replaceAll('_', ' ');
      }
    }
    return '';
  }

  String? _stringValue(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  double _numberValue(Object? value) {
    if (value == null) return 0;
    if (value is num && value.isFinite) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && parsed.isFinite) return parsed;
    }

    throw const FormatException('Dashboard query contains an invalid number.');
  }

  double _quantityValue(Map<String, dynamic> row) {
    const quantityKeys = [
      'quantity',
      'total_quantity',
      'total_stock_quantity',
      'stock_quantity',
      'current_quantity',
      'quantity_on_hand',
      'stock_on_hand',
      'available_stock',
      'on_hand',
    ];
    for (final key in quantityKeys) {
      if (row.containsKey(key)) return _numberValue(row[key]);
    }
    throw const FormatException(
      'Inventory quantity view row has no recognized quantity column.',
    );
  }

  String _friendlyMessage(PostgrestException error) {
    if (error.code == '42501' ||
        error.message.toLowerCase().contains('row-level security')) {
      return 'You do not have permission to load dashboard data.';
    }
    if (error.code == 'PGRST301' ||
        error.message.toLowerCase().contains('jwt')) {
      return 'Your session has expired. Please sign in again.';
    }
    return 'Unable to load dashboard data. ${error.message}';
  }
}
