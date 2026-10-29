import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/dashboard/data/dashboard_data.dart';
import 'activity_log_service.dart';
import 'stock_movement_service.dart';

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
  final ActivityLogService _activityLogService = ActivityLogService();

  Future<DashboardData> loadDashboard() async {
    try {
      final results = await Future.wait<Object>([
        (() async =>
            await _client.from('inventory_items').select('id,minimum_stock'))(),
        (() async =>
            await _client.from('inventory_items_with_quantity').select())(),
        (() async => await _client.from('inventory_alerts').select())(),
        (() async => await _client.from('warehouse_locations').select('id'))(),
        _movementService.getMovements(limit: 3),
        _activityLogService.getEntries(limit: 3),
      ]);

      final inventoryItems = _rows(results[0]);
      final quantityRows = _rows(results[1]);
      final alertRows = _rows(results[2]);
      final warehouseRows = _rows(results[3]);
      final movements = results[4] as List<StockMovement>;
      final activity = results[5] as List<ActivityLogEntry>;

      final quantityByItem = <String, double>{};
      var totalStockQuantity = 0.0;
      for (final row in quantityRows) {
        final itemId = _stringValue(row['item_id'] ?? row['id']);
        final quantity = _quantityValue(row);
        if (itemId == null) {
          throw const FormatException(
            'Inventory quantity view row is missing item_id or id.',
          );
        }
        totalStockQuantity += quantity;
        quantityByItem.update(
          itemId,
          (total) => total + quantity,
          ifAbsent: () => quantity,
        );
      }

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
          lowStockItems: lowStockItems,
          outOfStockItems: outOfStockItems,
          warehouseLocations: warehouseRows.length,
        ),
        recentMovements: movements,
        recentActivity: activity,
      );
    } on PostgrestException catch (error) {
      throw DashboardServiceException(_friendlyMessage(error));
    } on StockMovementServiceException catch (error) {
      throw DashboardServiceException(error.message);
    } on ActivityLogServiceException catch (error) {
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
