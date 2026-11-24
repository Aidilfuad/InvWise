import 'package:supabase_flutter/supabase_flutter.dart';

enum ReportType {
  inventorySummary('Inventory Summary Report'),
  stockMovements('Stock Movement Report'),
  lowStock('Low Stock Report'),
  warehouses('Warehouse Report'),
  activity('Activity Report');

  const ReportType(this.title);

  final String title;
}

class ReportMetric {
  const ReportMetric(this.label, this.value);

  final String label;
  final String value;
}

class ReportTable {
  const ReportTable({
    required this.title,
    required this.headers,
    required this.rows,
    required this.metrics,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final List<ReportMetric> metrics;
}

class ReportsData {
  const ReportsData({required this.generatedAt, required this.tables});

  final DateTime generatedAt;
  final Map<ReportType, ReportTable> tables;

  ReportTable operator [](ReportType type) => tables[type]!;
}

class ReportsServiceException implements Exception {
  const ReportsServiceException(this.message);

  final String message;

  @override
  String toString() => 'ReportsServiceException: $message';
}

class ReportsService {
  ReportsService();

  final SupabaseClient _client = Supabase.instance.client;

  Future<ReportsData> loadReports() async {
    try {
      final result = await Future.wait([
        _fetchAll(
          (from, to) => _client
              .from('inventory_items')
              .select(
                'id,sku,name,category_id,unit_id,minimum_stock,unit_price,'
                'is_active',
              )
              .order('id')
              .range(from, to),
        ),
        _fetchAll(
          (from, to) => _client
              .from('stock_levels')
              .select('item_id,location_id,quantity')
              .order('item_id')
              .order('location_id')
              .range(from, to),
        ),
        _fetchAll(
          (from, to) => _client
              .from('warehouse_locations')
              .select('id,code,name,address,capacity,is_active')
              .order('id')
              .range(from, to),
        ),
        _fetchAll(
          (from, to) => _client
              .from('categories')
              .select('id,name')
              .order('id')
              .range(from, to),
        ),
        _fetchAll(
          (from, to) => _client
              .from('units')
              .select('id,name,abbreviation')
              .order('id')
              .range(from, to),
        ),
        _fetchAll(
          (from, to) => _client
              .from('stock_movements')
              .select(
                'id,item_id,movement_type,quantity,source_location_id,'
                'destination_location_id,reference,occurred_at',
              )
              .order('occurred_at', ascending: false)
              .order('id', ascending: false)
              .range(from, to),
        ),
        _fetchAll(
          (from, to) => _client
              .from('activity_log')
              .select(
                'id,event_type,description,actor_profile_id,item_id,'
                'location_id,stock_movement_id,details,occurred_at',
              )
              .order('occurred_at', ascending: false)
              .order('id', ascending: false)
              .range(from, to),
        ),
      ]);

      final items = result[0];
      final stockLevels = result[1];
      final locations = result[2];
      final categories = result[3];
      final units = result[4];
      final movements = result[5];
      final activity = result[6];

      final categoriesById = _indexById(categories);
      final unitsById = _indexById(units);
      final locationsById = _indexById(locations);
      final quantitiesByItem = <String, double>{};
      final quantitiesByLocation = <String, double>{};
      final itemCountsByLocation = <String, Set<String>>{};
      for (final level in stockLevels) {
        final itemId = _string(level['item_id']);
        final locationId = _string(level['location_id']);
        final quantity = _number(level['quantity']);
        if (itemId == null || locationId == null) {
          throw const FormatException(
            'A stock level row is missing its item or location ID.',
          );
        }
        quantitiesByItem.update(
          itemId,
          (total) => total + quantity,
          ifAbsent: () => quantity,
        );
        quantitiesByLocation.update(
          locationId,
          (total) => total + quantity,
          ifAbsent: () => quantity,
        );
        if (quantity > 0) {
          final itemIdsAtLocation = itemCountsByLocation.putIfAbsent(
            locationId,
            () => <String>{},
          );
          itemIdsAtLocation.add(itemId);
        }
      }

      final itemsById = _indexById(items);
      final inventoryRows = <List<String>>[];
      final lowStockRows = <List<String>>[];
      var totalStock = 0.0;
      var totalStockValue = 0.0;
      for (final item in items) {
        final id = _requiredString(item, 'id');
        final quantity = quantitiesByItem[id] ?? 0;
        final minimum = _number(item['minimum_stock']);
        final unitPrice = _number(item['unit_price']);
        final stockValue = quantity * unitPrice;
        totalStock += quantity;
        totalStockValue += stockValue;
        final category = categoriesById[item['category_id']];
        final unit = unitsById[item['unit_id']];
        final isActive = item['is_active'] != false;
        final status = !isActive
            ? 'Inactive'
            : quantity <= 0
            ? 'Out of stock'
            : quantity <= minimum
            ? 'Low stock'
            : 'In stock';
        final row = [
          _display(item['sku']),
          _display(item['name']),
          _display(category?['name']),
          _display(unit?['abbreviation']),
          _formatNumber(quantity),
          _formatNumber(minimum),
          _formatNumber(unitPrice),
          _formatNumber(stockValue),
          status,
        ];
        inventoryRows.add(row);
        if (isActive &&
            (quantity <= 0 || (minimum > 0 && quantity <= minimum))) {
          lowStockRows.add([
            row[0],
            row[1],
            row[2],
            row[3],
            row[4],
            row[5],
            _formatNumber(minimum - quantity),
            quantity <= 0 ? 'Out of stock' : 'Low stock',
          ]);
        }
      }

      final movementRows = movements
          .map((movement) {
            final item = itemsById[movement['item_id']];
            final source = locationsById[movement['source_location_id']];
            final destination =
                locationsById[movement['destination_location_id']];
            return [
              _display(movement['occurred_at']),
              _display(item?['sku']),
              _display(item?['name']),
              _display(movement['movement_type']),
              _formatNumber(_number(movement['quantity'])),
              _display(source?['name']),
              _display(destination?['name']),
              _display(movement['reference']),
            ];
          })
          .toList(growable: false);

      final warehouseRows = locations
          .map((location) {
            final id = _requiredString(location, 'id');
            final quantity = quantitiesByLocation[id] ?? 0;
            return [
              _display(location['code']),
              _display(location['name']),
              _display(location['address']),
              _formatNullableNumber(location['capacity']),
              _formatNumber(quantity),
              '${itemCountsByLocation[id]?.length ?? 0}',
              location['is_active'] == false ? 'Inactive' : 'Active',
            ];
          })
          .toList(growable: false);

      final activityRows = activity
          .map((entry) {
            final details = _mapValue(entry['details']);
            final item = itemsById[entry['item_id']];
            final location = locationsById[entry['location_id']];
            final source = locationsById[details['source_location_id']];
            final destination =
                locationsById[details['destination_location_id']];
            final locationDescription = source != null || destination != null
                ? '${_display(source?['name'])} → '
                      '${_display(destination?['name'])}'
                : _display(location?['name']);
            return [
              _display(entry['occurred_at']),
              _display(entry['event_type']),
              _display(entry['description']),
              _display(item?['sku'] ?? details['sku']),
              _display(item?['name'] ?? details['item_name']),
              locationDescription,
              _formatNullableNumber(
                details['quantity'] ?? details['initial_quantity'],
              ),
              _display(entry['actor_profile_id']),
              _display(entry['stock_movement_id']),
            ];
          })
          .toList(growable: false);

      final outOfStockCount = lowStockRows
          .where((row) => row.last == 'Out of stock')
          .length;
      return ReportsData(
        generatedAt: DateTime.now(),
        tables: {
          ReportType.inventorySummary: ReportTable(
            title: ReportType.inventorySummary.title,
            headers: const [
              'SKU',
              'Item',
              'Category',
              'Unit',
              'On hand',
              'Minimum stock',
              'Unit price',
              'Stock value',
              'Status',
            ],
            rows: inventoryRows,
            metrics: [
              ReportMetric('Items', '${items.length}'),
              ReportMetric('Total stock', _formatNumber(totalStock)),
              ReportMetric('Stock value', _formatNumber(totalStockValue)),
              ReportMetric('Low stock', '${lowStockRows.length}'),
            ],
          ),
          ReportType.stockMovements: ReportTable(
            title: ReportType.stockMovements.title,
            headers: const [
              'Occurred at',
              'SKU',
              'Item',
              'Movement',
              'Quantity',
              'Source location',
              'Destination location',
              'Reference',
            ],
            rows: movementRows,
            metrics: [
              ReportMetric('Movements', '${movements.length}'),
              ReportMetric(
                'Receipts',
                '${_countBy(movements, 'movement_type', 'receipt')}',
              ),
              ReportMetric(
                'Issues',
                '${_countBy(movements, 'movement_type', 'issue')}',
              ),
              ReportMetric(
                'Transfers',
                '${_countBy(movements, 'movement_type', 'transfer')}',
              ),
              ReportMetric(
                'Returns',
                '${_countBy(movements, 'movement_type', 'return')}',
              ),
              ReportMetric(
                'Adjustments',
                '${_countBy(movements, 'movement_type', 'adjustment')}',
              ),
            ],
          ),
          ReportType.lowStock: ReportTable(
            title: ReportType.lowStock.title,
            headers: const [
              'SKU',
              'Item',
              'Category',
              'Unit',
              'On hand',
              'Minimum stock',
              'Shortage',
              'Status',
            ],
            rows: lowStockRows,
            metrics: [
              ReportMetric('Low stock items', '${lowStockRows.length}'),
              ReportMetric('Out of stock', '$outOfStockCount'),
              ReportMetric(
                'Locations with stock',
                '${quantitiesByLocation.values.where((quantity) => quantity > 0).length}',
              ),
              ReportMetric('Generated', _dateOnly(DateTime.now())),
            ],
          ),
          ReportType.warehouses: ReportTable(
            title: ReportType.warehouses.title,
            headers: const [
              'Code',
              'Warehouse',
              'Address',
              'Capacity',
              'Stock quantity',
              'Items stocked',
              'Status',
            ],
            rows: warehouseRows,
            metrics: [
              ReportMetric('Locations', '${locations.length}'),
              ReportMetric(
                'Active locations',
                '${locations.where((row) => row['is_active'] != false).length}',
              ),
              ReportMetric('Stock quantity', _formatNumber(totalStock)),
              ReportMetric('Generated', _dateOnly(DateTime.now())),
            ],
          ),
          ReportType.activity: ReportTable(
            title: ReportType.activity.title,
            headers: const [
              'Occurred at',
              'Event',
              'Description',
              'SKU',
              'Item',
              'Location',
              'Quantity',
              'Actor profile ID',
              'Stock movement ID',
            ],
            rows: activityRows,
            metrics: [
              ReportMetric('Events', '${activity.length}'),
              ReportMetric(
                'Inventory events',
                '${activity.where((row) => _string(row['event_type'])?.startsWith('inventory_') == true).length}',
              ),
              ReportMetric(
                'Stock events',
                '${activity.where((row) => _string(row['event_type'])?.startsWith('inventory_') != true).length}',
              ),
              ReportMetric('Generated', _dateOnly(DateTime.now())),
            ],
          ),
        },
      );
    } on PostgrestException catch (error) {
      throw ReportsServiceException(_friendlyMessage(error));
    } on ReportsServiceException {
      rethrow;
    } catch (error) {
      throw ReportsServiceException(
        'Unable to load reports. Please try again. ($error)',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAll(
    Future<List<Map<String, dynamic>>> Function(int from, int to) loadPage,
  ) async {
    const pageSize = 1000;
    final rows = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final page = await loadPage(offset, offset + pageSize - 1);
      rows.addAll(page);
      if (page.length < pageSize) return rows;
      offset += pageSize;
    }
  }

  Map<String, Map<String, dynamic>> _indexById(
    List<Map<String, dynamic>> rows,
  ) => {
    for (final row in rows)
      if (row['id'] is String) row['id'] as String: row,
  };

  Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  int _countBy(List<Map<String, dynamic>> rows, String key, String value) =>
      rows.where((row) => _string(row[key]) == value).length;

  String? _string(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  String _requiredString(Map<String, dynamic> row, String key) {
    final value = _string(row[key]);
    if (value != null) return value;
    throw FormatException('Report row is missing required "$key".');
  }

  String _display(Object? value) => value == null ? '' : value.toString();

  double _number(Object? value) {
    if (value == null) return 0;
    if (value is num && value.isFinite) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && parsed.isFinite) return parsed;
    }
    throw const FormatException('A report row contains an invalid number.');
  }

  String _formatNullableNumber(Object? value) =>
      value == null ? '' : _formatNumber(_number(value));

  String _formatNumber(double value) =>
      value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _friendlyMessage(PostgrestException error) {
    if (error.code == '42501' ||
        error.message.toLowerCase().contains('row-level security')) {
      return 'You do not have permission to load reports.';
    }
    if (error.code == 'PGRST301' ||
        error.message.toLowerCase().contains('jwt')) {
      return 'Your session has expired. Please sign in again.';
    }
    return 'Unable to load reports. ${error.message}';
  }
}
