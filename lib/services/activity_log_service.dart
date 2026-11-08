import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ActivityEventType {
  inventoryCreated('inventory_created', 'Create Item'),
  inventoryUpdated('inventory_updated', 'Update Item'),
  inventoryDeleted('inventory_deleted', 'Delete Item'),
  stockAdjustment('stock_adjustment', 'Stock Adjustment'),
  receipt('receipt', 'Receipt'),
  issue('issue', 'Issue'),
  returnItem('return', 'Return'),
  transfer('transfer', 'Transfer');

  const ActivityEventType(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static ActivityEventType fromDatabase(Object? value) {
    final normalized = value?.toString().toLowerCase();
    return ActivityEventType.values.firstWhere(
      (type) => type.databaseValue == normalized,
      orElse: () =>
          throw FormatException('Unknown activity event type "$value".'),
    );
  }
}

class ActivityLogServiceException implements Exception {
  const ActivityLogServiceException(this.message);

  final String message;

  @override
  String toString() => 'ActivityLogServiceException: $message';
}

class ActivityLogEntry {
  const ActivityLogEntry({
    required this.id,
    required this.type,
    required this.description,
    required this.details,
    required this.occurredAt,
    this.actorProfileId,
    this.itemId,
    this.itemName,
    this.itemSku,
    this.locationId,
    this.locationName,
    this.stockMovementId,
  });

  final String id;
  final ActivityEventType type;
  final String description;
  final Map<String, dynamic> details;
  final DateTime occurredAt;
  final String? actorProfileId;
  final String? itemId;
  final String? itemName;
  final String? itemSku;
  final String? locationId;
  final String? locationName;
  final String? stockMovementId;

  String get title => itemName ?? _detailString('item_name') ?? description;
  String get sku => itemSku ?? _detailString('sku') ?? '';
  String get reference => _detailString('reference') ?? '';

  String get context {
    final location = locationName ?? _detailString('location_name');
    final source = _detailString('source_location_name');
    final destination = _detailString('destination_location_name');
    final route = source != null || destination != null
        ? '${source ?? 'Unknown'} → ${destination ?? 'Unknown'}'
        : location;
    final parts = <String>[
      if (sku.isNotEmpty) sku,
      if (route?.isNotEmpty == true) route!,
      if (reference.isNotEmpty) reference,
    ];
    return parts.join(' · ');
  }

  String get quantityLabel {
    final quantity = _detailNumber('quantity');
    if (quantity == null) return '';
    final formatted = quantity
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    final prefix = switch (type) {
      ActivityEventType.receipt || ActivityEventType.returnItem => '+',
      ActivityEventType.issue => '−',
      ActivityEventType.stockAdjustment =>
        _detailString('operation')?.toLowerCase() == 'remove' ? '−' : '+',
      ActivityEventType.transfer ||
      ActivityEventType.inventoryCreated ||
      ActivityEventType.inventoryUpdated ||
      ActivityEventType.inventoryDeleted => '',
    };
    return '$prefix$formatted units';
  }

  String? _detailString(String key) {
    final value = details[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  double? _detailNumber(String key) {
    final value = details[key];
    if (value is num && value.isFinite) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class ActivityLogService {
  ActivityLogService();

  final SupabaseClient _client = Supabase.instance.client;

  static const String _table = 'activity_log';

  Future<List<ActivityLogEntry>> getEntries({
    int limit = 100,
    String? itemId,
  }) async {
    if (limit <= 0) {
      throw const ActivityLogServiceException(
        'The activity result limit must be greater than zero.',
      );
    }
    if (itemId != null && itemId.trim().isEmpty) {
      throw const ActivityLogServiceException(
        'The activity item identifier must not be empty.',
      );
    }

    try {
      final selectedRows = _client
          .from(_table)
          .select(
            'id,event_type,description,actor_profile_id,item_id,location_id,'
            'stock_movement_id,details,occurred_at',
          );
      final rows = itemId == null
          ? await selectedRows
                .order('occurred_at', ascending: false)
                .order('id', ascending: false)
                .limit(limit)
          : await selectedRows
                .eq('item_id', itemId.trim())
                .order('occurred_at', ascending: false)
                .order('id', ascending: false)
                .limit(limit);
      if (rows.isEmpty) return const [];

      final itemIds = rows
          .map((row) => row['item_id'] as String?)
          .whereType<String>()
          .toSet();
      final locationIds = <String>{};
      for (final row in rows) {
        final locationId = row['location_id'] as String?;
        if (locationId != null) locationIds.add(locationId);
        final details = row['details'];
        if (details is Map) {
          for (final key in const [
            'source_location_id',
            'destination_location_id',
          ]) {
            final id = details[key];
            if (id is String && id.isNotEmpty) locationIds.add(id);
          }
        }
      }
      final items = itemIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
                .from('inventory_items')
                .select('id,name,sku')
                .inFilter('id', itemIds.toList());
      final locations = locationIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
                .from('warehouse_locations')
                .select('id,name')
                .inFilter('id', locationIds.toList());
      final itemsById = {for (final item in items) item['id'] as String: item};
      final locationsById = {
        for (final location in locations)
          location['id'] as String: location['name'] as String,
      };

      return rows
          .map(
            (row) => _fromMap(
              row,
              item: itemsById[row['item_id']],
              locationsById: locationsById,
            ),
          )
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw ActivityLogServiceException(
        _friendlyMessage(error, 'load activity history'),
      );
    } on ActivityLogServiceException {
      rethrow;
    } catch (error) {
      throw ActivityLogServiceException(
        'Unable to load activity history. Please try again. ($error)',
      );
    }
  }

  Future<void> recordEvent({
    required ActivityEventType type,
    required String description,
    String? itemId,
    String? locationId,
    String? stockMovementId,
    Map<String, dynamic> details = const {},
  }) async {
    try {
      final actorProfileId = await _currentProfileId();
      await _client.from(_table).insert({
        'event_type': type.databaseValue,
        'description': description.trim(),
        'actor_profile_id': actorProfileId,
        'item_id': itemId,
        'location_id': locationId,
        'stock_movement_id': stockMovementId,
        'details': details,
      });
    } on PostgrestException catch (error) {
      throw ActivityLogServiceException(
        _friendlyMessage(error, 'record activity'),
      );
    } on ActivityLogServiceException {
      rethrow;
    } catch (error) {
      if (error is ActivityLogServiceException) rethrow;
      throw ActivityLogServiceException(
        'Unable to record activity. Please try again. ($error)',
      );
    }
  }

  Future<String?> _currentProfileId() async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null || authUserId.isEmpty) return null;
    try {
      final profile = await _client
          .from('profiles')
          .select('id')
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      return profile?['id'] as String?;
    } on PostgrestException catch (error) {
      throw ActivityLogServiceException(
        _friendlyMessage(error, 'load the current user profile'),
      );
    } catch (error) {
      throw ActivityLogServiceException(
        'Unable to load the current user profile. ($error)',
      );
    }
  }

  ActivityLogEntry _fromMap(
    Map<String, dynamic> row, {
    required Map<String, dynamic>? item,
    required Map<String, String> locationsById,
  }) {
    final rawDetails = row['details'];
    final details = rawDetails is Map
        ? Map<String, dynamic>.from(rawDetails)
        : <String, dynamic>{};
    final locationId = row['location_id'] as String?;
    final sourceLocationId = details['source_location_id'] as String?;
    final destinationLocationId = details['destination_location_id'] as String?;
    final locationName = locationId == null ? null : locationsById[locationId];
    if (sourceLocationId != null) {
      details['source_location_name'] = locationsById[sourceLocationId];
    }
    if (destinationLocationId != null) {
      details['destination_location_name'] =
          locationsById[destinationLocationId];
    }
    if (locationName != null) details['location_name'] = locationName;
    return ActivityLogEntry(
      id: _requiredString(row, 'id'),
      type: ActivityEventType.fromDatabase(row['event_type']),
      description: _requiredString(row, 'description'),
      details: details,
      occurredAt: _dateValue(row['occurred_at']) ?? DateTime.now(),
      actorProfileId: row['actor_profile_id'] as String?,
      itemId: row['item_id'] as String?,
      itemName: item?['name'] as String?,
      itemSku: item?['sku'] as String?,
      locationId: locationId,
      locationName: locationName,
      stockMovementId: row['stock_movement_id'] as String?,
    );
  }

  String _friendlyMessage(PostgrestException error, String action) {
    if (error.code == '42501' ||
        error.message.toLowerCase().contains('row-level security')) {
      return 'You do not have permission to $action.';
    }
    if (error.code == 'PGRST301' ||
        error.message.toLowerCase().contains('jwt')) {
      return 'Your session has expired. Please sign in again.';
    }
    return 'Unable to $action. ${error.message}';
  }
}

String _requiredString(Map<String, dynamic> row, String column) {
  final value = row[column];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('Activity row is missing required column "$column".');
}

DateTime? _dateValue(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

void reportActivityLogFailure(Object error) {
  debugPrint('[ActivityLogService] Activity was not recorded: $error');
}
