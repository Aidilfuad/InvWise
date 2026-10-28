import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WarehouseLocationServiceException implements Exception {
  const WarehouseLocationServiceException(this.message);

  final String message;

  @override
  String toString() => 'WarehouseLocationServiceException: $message';
}

class WarehouseLocation {
  const WarehouseLocation({
    required this.id,
    required this.name,
    required this.code,
    required this.capacity,
    required this.usage,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.description,
    this.address,
  });

  final String id;
  final String name;
  final String code;
  final String? description;
  final String? address;
  final double capacity;
  final double usage;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get status => isActive ? 'Active' : 'Inactive';
  String get displayAddress =>
      address?.trim().isNotEmpty == true ? address! : description ?? '';
  double get usageRatio =>
      capacity <= 0 ? 0 : (usage / capacity).clamp(0, 1).toDouble();
}

class WarehouseLocationsSummary {
  const WarehouseLocationsSummary({
    required this.activeLocations,
    required this.totalCapacity,
    required this.utilizationPercent,
  });

  final int activeLocations;
  final double totalCapacity;
  final int utilizationPercent;
}

class WarehouseLocationService {
  WarehouseLocationService();

  final SupabaseClient _client = Supabase.instance.client;

  static const String _table = 'warehouse_locations';
  static const String _stockLevelsTable = 'stock_levels';

  Future<List<WarehouseLocation>> getLocations({
    bool includeInactive = false,
  }) async {
    try {
      var query = _client.from(_table).select();
      if (!includeInactive) {
        query = query.eq('is_active', true);
      }
      final rows = await query.order('name', ascending: true);
      final usageByLocation = await _getUsageByLocation(
        rows.map((row) => row['id'] as String).toList(),
      );
      return rows
          .map<WarehouseLocation>(
            (row) => _fromMap(row, usage: usageByLocation[row['id']] ?? 0),
          )
          .toList(growable: false);
    } on PostgrestException catch (e) {
      _logFailure('load warehouse locations', e, StackTrace.current);
      throw WarehouseLocationServiceException(
        _friendlyMessage(e, 'load warehouse locations'),
      );
    } catch (e, stackTrace) {
      _logFailure('map warehouse locations', e, stackTrace);
      if (e is WarehouseLocationServiceException) rethrow;
      throw const WarehouseLocationServiceException(
        'Unable to load warehouse locations. Please check your connection and '
        'try again.',
      );
    }
  }

  Future<WarehouseLocation> getLocationById(String id) async {
    final locationId = _validatedId(id);
    try {
      final row = await _client
          .from(_table)
          .select()
          .eq('id', locationId)
          .maybeSingle();
      if (row == null) {
        throw const WarehouseLocationServiceException(
          'Warehouse location not found.',
        );
      }
      final usage = await _getUsageByLocation([locationId]);
      return _fromMap(row, usage: usage[locationId] ?? 0);
    } on PostgrestException catch (e) {
      _logFailure('load warehouse location', e, StackTrace.current);
      throw WarehouseLocationServiceException(
        _friendlyMessage(e, 'load the warehouse location'),
      );
    } on WarehouseLocationServiceException {
      rethrow;
    } catch (e, stackTrace) {
      _logFailure('map warehouse location', e, stackTrace);
      throw const WarehouseLocationServiceException(
        'Unable to load the warehouse location. Please try again.',
      );
    }
  }

  Future<WarehouseLocationsSummary> getSummary() async {
    final locations = await getLocations(includeInactive: true);
    final activeLocations = locations
        .where((location) => location.isActive)
        .toList();
    final totalCapacity = activeLocations.fold<double>(
      0,
      (total, location) => total + location.capacity,
    );
    final totalUsage = activeLocations.fold<double>(
      0,
      (total, location) => total + location.usage,
    );
    final utilizationPercent = totalCapacity <= 0
        ? 0
        : ((totalUsage / totalCapacity) * 100).round().clamp(0, 100).toInt();
    return WarehouseLocationsSummary(
      activeLocations: activeLocations.length,
      totalCapacity: totalCapacity,
      utilizationPercent: utilizationPercent,
    );
  }

  Future<void> createLocation({
    required String name,
    required String code,
    required double capacity,
    String? description,
    String? address,
  }) async {
    final payload = _validatedPayload(
      name: name,
      code: code,
      capacity: capacity,
      description: description,
      address: address,
    );

    try {
      await _client.from(_table).insert({...payload, 'is_active': true});
    } on PostgrestException catch (e) {
      throw WarehouseLocationServiceException(
        _friendlyMessage(e, 'create the warehouse location'),
      );
    } catch (e) {
      if (e is WarehouseLocationServiceException) rethrow;
      throw const WarehouseLocationServiceException(
        'Unable to create the warehouse location. Please try again.',
      );
    }
  }

  Future<void> updateLocation({
    required String id,
    required String name,
    required String code,
    required double capacity,
    String? description,
    String? address,
    bool? isActive,
  }) async {
    final locationId = _validatedId(id);
    final payload = _validatedPayload(
      name: name,
      code: code,
      capacity: capacity,
      description: description,
      address: address,
    );
    payload['updated_at'] = DateTime.now().toUtc().toIso8601String();
    if (isActive != null) payload['is_active'] = isActive;

    try {
      final rows = await _client
          .from(_table)
          .update(payload)
          .eq('id', locationId)
          .select('id');
      if (rows.isEmpty) {
        throw const WarehouseLocationServiceException(
          'Warehouse location not found, or you do not have permission to '
          'update it.',
        );
      }
    } on PostgrestException catch (e) {
      throw WarehouseLocationServiceException(
        _friendlyMessage(e, 'update the warehouse location'),
      );
    } on WarehouseLocationServiceException {
      rethrow;
    } catch (e) {
      throw const WarehouseLocationServiceException(
        'Unable to update the warehouse location. Please try again.',
      );
    }
  }

  Future<void> deleteLocation(String id) async {
    final locationId = _validatedId(id);
    try {
      final rows = await _client
          .from(_table)
          .delete()
          .eq('id', locationId)
          .select('id');
      if (rows.isEmpty) {
        throw const WarehouseLocationServiceException(
          'Warehouse location not found, or you do not have permission to '
          'delete it.',
        );
      }
    } on PostgrestException catch (e) {
      throw WarehouseLocationServiceException(
        _friendlyMessage(e, 'delete the warehouse location'),
      );
    } on WarehouseLocationServiceException {
      rethrow;
    } catch (e) {
      throw const WarehouseLocationServiceException(
        'Unable to delete the warehouse location. Please try again.',
      );
    }
  }

  Future<Map<String, double>> _getUsageByLocation(
    List<String> locationIds,
  ) async {
    if (locationIds.isEmpty) return const {};
    late final List<Map<String, dynamic>> stockRows;
    try {
      stockRows = await _client
          .from(_stockLevelsTable)
          .select('location_id,quantity')
          .inFilter('location_id', locationIds);
    } catch (error, stackTrace) {
      _logFailure('load stock-level usage', error, stackTrace);
      rethrow;
    }
    final usage = <String, double>{};
    for (final row in stockRows) {
      final locationId = row['location_id'] as String;
      final quantity = _numberValue(row['quantity']);
      usage.update(
        locationId,
        (total) => total + quantity,
        ifAbsent: () => quantity,
      );
    }
    return usage;
  }

  WarehouseLocation _fromMap(
    Map<String, dynamic> map, {
    required double usage,
  }) => WarehouseLocation(
    id: _requiredString(map, 'id'),
    name: _requiredString(map, 'name'),
    code: _requiredString(map, 'code'),
    description: map['description'] as String?,
    address: map['address'] as String?,
    capacity: _numberValue(map['capacity']),
    usage: usage,
    isActive: map['is_active'] as bool? ?? true,
    createdAt: _dateValue(map['created_at']),
    updatedAt: _dateValue(map['updated_at']),
  );

  Map<String, dynamic> _validatedPayload({
    required String name,
    required String code,
    required double capacity,
    String? description,
    String? address,
  }) {
    final trimmedName = name.trim();
    final trimmedCode = code.trim();
    if (trimmedName.isEmpty || trimmedCode.isEmpty) {
      throw const WarehouseLocationServiceException(
        'Please enter a location name and code.',
      );
    }
    if (!capacity.isFinite || capacity < 0) {
      throw const WarehouseLocationServiceException(
        'Enter a valid non-negative capacity.',
      );
    }

    return {
      'name': trimmedName,
      'code': trimmedCode,
      'description': _cleanOptional(description),
      'address': _cleanOptional(address),
      'capacity': capacity,
    };
  }

  String? _cleanOptional(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _validatedId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw const WarehouseLocationServiceException(
        'Warehouse location not found.',
      );
    }
    return trimmed;
  }

  String _friendlyMessage(PostgrestException e, String action) {
    final message = e.message.toLowerCase();
    if (e.code == '23505') {
      return 'A warehouse location with this code already exists.';
    }
    if (e.code == '23503') {
      return 'This location is used by stock records and cannot be deleted.';
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
    return 'Unable to $action. Please try again.';
  }

  void _logFailure(String action, Object error, StackTrace stackTrace) {
    if (error is PostgrestException) {
      debugPrint(
        '[WarehouseLocationService] $action failed: '
        'code=${error.code}, message=${error.message}, '
        'details=${error.details}, hint=${error.hint}',
      );
    } else {
      debugPrint('[WarehouseLocationService] $action failed: $error');
    }
    debugPrintStack(stackTrace: stackTrace);
  }
}

String _requiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('Warehouse location is missing required field "$key".');
}

double _numberValue(Object? value) {
  if (value == null) return 0;
  if (value is num && value.isFinite) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed.isFinite) return parsed;
  }
  throw const FormatException('Warehouse location has an invalid number.');
}

DateTime? _dateValue(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
