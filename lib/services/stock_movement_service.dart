import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'activity_log_service.dart';

enum StockMovementType {
  receipt('receipt', 'Receipt'),
  issue('issue', 'Issue'),
  transfer('transfer', 'Transfer'),
  returnItem('return', 'Return');

  const StockMovementType(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static StockMovementType fromDatabase(Object? value) {
    final normalized = value?.toString().toLowerCase();
    return StockMovementType.values.firstWhere(
      (type) => type.databaseValue == normalized,
      orElse: () =>
          throw FormatException('Unknown stock movement type "$value".'),
    );
  }
}

class StockMovementServiceException implements Exception {
  const StockMovementServiceException(this.message);

  final String message;

  @override
  String toString() => 'StockMovementServiceException: $message';
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.sku,
    required this.type,
    required this.quantity,
    required this.occurredAt,
    this.sourceLocationId,
    this.sourceLocationName,
    this.destinationLocationId,
    this.destinationLocationName,
    this.reference,
    this.notes,
    this.performedBy,
  });

  final String id;
  final String itemId;
  final String itemName;
  final String sku;
  final StockMovementType type;
  final double quantity;
  final String? sourceLocationId;
  final String? sourceLocationName;
  final String? destinationLocationId;
  final String? destinationLocationName;
  final String? reference;
  final String? notes;
  final String? performedBy;
  final DateTime occurredAt;

  String get description {
    final places = switch (type) {
      StockMovementType.receipt ||
      StockMovementType.returnItem => destinationLocationName,
      StockMovementType.issue => sourceLocationName,
      StockMovementType.transfer =>
        '${sourceLocationName ?? 'Unknown'} → '
            '${destinationLocationName ?? 'Unknown'}',
    };
    final parts = <String>[
      type.label,
      if (places != null && places.isNotEmpty) places,
      if (reference?.isNotEmpty == true) reference!,
      if (notes?.isNotEmpty == true) notes!,
    ];
    return parts.join(' · ');
  }
}

class StockMovementService {
  StockMovementService();

  final SupabaseClient _client = Supabase.instance.client;
  final ActivityLogService _activityLogService = ActivityLogService();

  String? lastActivityLogWarning;

  static const String _movementsTable = 'stock_movements';
  static const String _stockLevelsTable = 'stock_levels';

  Future<List<StockMovement>> getMovements({int limit = 100}) async {
    if (limit <= 0) {
      throw const StockMovementServiceException(
        'The movement result limit must be greater than zero.',
      );
    }
    try {
      final rows = await _client
          .from(_movementsTable)
          .select(
            'id,item_id,movement_type,quantity,source_location_id,'
            'destination_location_id,reference,notes,performed_by,occurred_at',
          )
          .order('occurred_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);
      if (rows.isEmpty) return const [];

      final itemIds = rows.map((row) => row['item_id'] as String).toSet();
      final locationIds = rows
          .expand(
            (row) => [
              row['source_location_id'] as String?,
              row['destination_location_id'] as String?,
            ],
          )
          .whereType<String>()
          .toSet();
      final itemRows = await _client
          .from('inventory_items')
          .select('id,name,sku')
          .inFilter('id', itemIds.toList());
      final locationRows = locationIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
                .from('warehouse_locations')
                .select('id,name')
                .inFilter('id', locationIds.toList());
      final itemsById = {
        for (final item in itemRows) item['id'] as String: item,
      };
      final locationsById = {
        for (final location in locationRows)
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
      throw StockMovementServiceException(
        _friendlyMessage(error, 'load stock movements'),
      );
    } on StockMovementServiceException {
      rethrow;
    } catch (error) {
      throw StockMovementServiceException(
        'Unable to load stock movements. Please try again. ($error)',
      );
    }
  }

  Future<void> createMovement({
    required String itemId,
    required StockMovementType type,
    required double quantity,
    String? sourceLocationId,
    String? destinationLocationId,
    String? reference,
    String? notes,
  }) async {
    lastActivityLogWarning = null;
    final item = _validatedId(itemId, 'item');
    if (!quantity.isFinite || quantity <= 0) {
      throw const StockMovementServiceException(
        'Enter a quantity greater than zero.',
      );
    }
    final requestedSource = _optionalId(sourceLocationId);
    final requestedDestination = _optionalId(destinationLocationId);
    final source = switch (type) {
      StockMovementType.receipt || StockMovementType.returnItem => null,
      StockMovementType.issue || StockMovementType.transfer => requestedSource,
    };
    final destination = switch (type) {
      StockMovementType.issue => null,
      StockMovementType.receipt ||
      StockMovementType.transfer ||
      StockMovementType.returnItem => requestedDestination,
    };
    _validateLocations(type, source, destination);

    await _validateReferences(
      itemId: item,
      sourceLocationId: source,
      destinationLocationId: destination,
    );
    final performedBy = await _getCurrentProfileId();

    final affected = <String, double>{};
    try {
      switch (type) {
        case StockMovementType.receipt:
        case StockMovementType.returnItem:
          affected[destination!] = await _changeStock(
            itemId: item,
            locationId: destination,
            delta: quantity,
          );
        case StockMovementType.issue:
          affected[source!] = await _changeStock(
            itemId: item,
            locationId: source,
            delta: -quantity,
          );
        case StockMovementType.transfer:
          final balances = await Future.wait([
            _getStock(item, source!),
            _getStock(item, destination!),
          ]);
          final sourceQuantity = balances[0];
          final destinationQuantity = balances[1];
          if (sourceQuantity < quantity) {
            throw StockMovementServiceException(
              'Cannot transfer $quantity units. Only $sourceQuantity units '
              'are available at the source location.',
            );
          }

          affected[source] = sourceQuantity;
          affected[destination] = destinationQuantity;
          await _setStock(
            itemId: item,
            locationId: source,
            quantity: sourceQuantity - quantity,
          );
          await _setStock(
            itemId: item,
            locationId: destination,
            quantity: destinationQuantity + quantity,
          );
      }

      final payload = <String, dynamic>{
        'item_id': item,
        'movement_type': type.databaseValue,
        'quantity': quantity,
        'source_location_id': source,
        'destination_location_id': destination,
        'reference': _cleanOptional(reference),
        'notes': _cleanOptional(notes),
        'performed_by': performedBy,
        'occurred_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (kDebugMode) {
        debugPrint(
          '[StockMovementService] inserting stock movement: '
          'item_id=${payload['item_id']}, '
          'source_location_id=${payload['source_location_id']}, '
          'destination_location_id=${payload['destination_location_id']}, '
          'performed_by=${payload['performed_by']}',
        );
      }
      final movementRow = await _client
          .from(_movementsTable)
          .insert(payload)
          .select('id')
          .single();
      await _recordActivity(
        type: switch (type) {
          StockMovementType.receipt => ActivityEventType.receipt,
          StockMovementType.issue => ActivityEventType.issue,
          StockMovementType.returnItem => ActivityEventType.returnItem,
          StockMovementType.transfer => ActivityEventType.transfer,
        },
        description:
            '${type.label}: ${_formatQuantity(quantity)} units for item $item.',
        itemId: item,
        locationId: destination ?? source,
        stockMovementId: movementRow['id'] as String,
        details: {
          'quantity': quantity,
          'source_location_id': source,
          'destination_location_id': destination,
          if (reference?.trim().isNotEmpty == true)
            'reference': reference!.trim(),
          if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
        },
      );
    } on PostgrestException catch (error) {
      _logPostgrestFailure('insert stock movement', error);
      final rollbackError = await _restoreStock(item, affected);
      final failure = _friendlyMessage(error, 'save the stock movement');
      if (rollbackError != null) {
        throw StockMovementServiceException(
          '$failure Stock levels could not be rolled back: $rollbackError',
        );
      }
      throw StockMovementServiceException(failure);
    } on StockMovementServiceException catch (error) {
      final rollbackError = await _restoreStock(item, affected);
      if (rollbackError != null) {
        throw StockMovementServiceException(
          '${error.message} Stock levels could not be rolled back: '
          '$rollbackError',
        );
      }
      rethrow;
    }
  }

  Future<void> _recordActivity({
    required ActivityEventType type,
    required String description,
    required String itemId,
    required String? locationId,
    required String stockMovementId,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _activityLogService.recordEvent(
        type: type,
        description: description,
        itemId: itemId,
        locationId: locationId,
        stockMovementId: stockMovementId,
        details: details,
      );
    } on ActivityLogServiceException catch (error) {
      lastActivityLogWarning =
          'The stock movement succeeded, but activity logging failed: '
          '${error.message}';
      reportActivityLogFailure(error);
    }
  }

  String _formatQuantity(double quantity) =>
      quantity.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');

  Future<String> _getCurrentProfileId() async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null || authUserId.isEmpty) {
      throw const StockMovementServiceException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final profile = await _client
          .from('profiles')
          .select('id')
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      final profileId = profile?['id'] as String?;
      if (kDebugMode) {
        debugPrint(
          '[StockMovementService] profiles validation result: '
          'auth_user_id=$authUserId, profile_id=$profileId',
        );
      }
      if (profileId == null || profileId.isEmpty) {
        throw const StockMovementServiceException(
          'Your user profile could not be found. Please contact an administrator.',
        );
      }
      return profileId;
    } on PostgrestException catch (error) {
      _logPostgrestFailure('load performer profile', error);
      throw StockMovementServiceException(
        _friendlyMessage(error, 'load the current user profile'),
      );
    } on StockMovementServiceException {
      rethrow;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[StockMovementService] profile lookup failed: $error');
      }
      throw const StockMovementServiceException(
        'Unable to verify your user profile. Please try again.',
      );
    }
  }

  Future<void> _validateReferences({
    required String itemId,
    required String? sourceLocationId,
    required String? destinationLocationId,
  }) async {
    final selectedLocationIds = {
      ?sourceLocationId,
      ?destinationLocationId,
    }.toList(growable: false);
    if (kDebugMode) {
      debugPrint(
        '[StockMovementService] validating selected ids: '
        'item_id=$itemId, source_location_id=$sourceLocationId, '
        'destination_location_id=$destinationLocationId',
      );
    }

    try {
      final itemRow = await _client
          .from('inventory_items')
          .select('id')
          .eq('id', itemId)
          .maybeSingle();
      if (kDebugMode) {
        debugPrint(
          '[StockMovementService] inventory_items validation result: '
          '${itemRow == null ? 'not found' : 'found id=${itemRow['id']}'}',
        );
      }
      if (itemRow == null) {
        throw const StockMovementServiceException(
          'The selected inventory item no longer exists or is not accessible.',
        );
      }

      if (selectedLocationIds.isEmpty) return;
      final locationRows = await _client
          .from('warehouse_locations')
          .select('id')
          .inFilter('id', selectedLocationIds);
      final foundLocationIds = locationRows
          .map((row) => row['id'] as String)
          .toSet();
      if (kDebugMode) {
        debugPrint(
          '[StockMovementService] warehouse_locations validation result: '
          'requested=$selectedLocationIds, found=$foundLocationIds',
        );
      }
      final missingLocationIds = selectedLocationIds
          .where((id) => !foundLocationIds.contains(id))
          .toList(growable: false);
      if (missingLocationIds.isNotEmpty) {
        throw StockMovementServiceException(
          'Selected warehouse location(s) no longer exist or are not '
          'accessible: ${missingLocationIds.join(', ')}.',
        );
      }
    } on PostgrestException catch (error) {
      _logPostgrestFailure('validate movement references', error);
      throw StockMovementServiceException(
        _friendlyMessage(error, 'validate the selected item and locations'),
      );
    } on StockMovementServiceException {
      rethrow;
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[StockMovementService] reference validation failed: $error',
        );
      }
      throw const StockMovementServiceException(
        'Unable to verify the selected item and locations. Please try again.',
      );
    }
  }

  void _logPostgrestFailure(String operation, PostgrestException error) {
    if (!kDebugMode) return;
    debugPrint(
      '[StockMovementService] $operation failed: code=${error.code}, '
      'message=${error.message}, details=${error.details}, hint=${error.hint}',
    );
  }

  StockMovement _fromMap(
    Map<String, dynamic> row, {
    required Map<String, dynamic>? item,
    required Map<String, String> locationsById,
  }) {
    final sourceId = row['source_location_id'] as String?;
    final destinationId = row['destination_location_id'] as String?;
    return StockMovement(
      id: _requiredString(row, 'id'),
      itemId: _requiredString(row, 'item_id'),
      itemName: item?['name'] as String? ?? 'Unknown item',
      sku: item?['sku'] as String? ?? '',
      type: StockMovementType.fromDatabase(row['movement_type']),
      quantity: _numberValue(row['quantity']),
      sourceLocationId: sourceId,
      sourceLocationName: sourceId == null ? null : locationsById[sourceId],
      destinationLocationId: destinationId,
      destinationLocationName: destinationId == null
          ? null
          : locationsById[destinationId],
      reference: row['reference'] as String?,
      notes: row['notes'] as String?,
      performedBy: row['performed_by'] as String?,
      occurredAt: _dateValue(row['occurred_at']) ?? DateTime.now(),
    );
  }

  Future<double> _changeStock({
    required String itemId,
    required String locationId,
    required double delta,
  }) async {
    final current = await _getStock(itemId, locationId);
    final updated = current + delta;
    if (updated < 0) {
      throw const StockMovementServiceException(
        'Cannot issue or transfer more stock than is available.',
      );
    }
    await _setStock(itemId: itemId, locationId: locationId, quantity: updated);
    return current;
  }

  Future<void> _setStock({
    required String itemId,
    required String locationId,
    required double quantity,
  }) async {
    await _client.from(_stockLevelsTable).upsert({
      'item_id': itemId,
      'location_id': locationId,
      'quantity': quantity,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'item_id,location_id');
  }

  Future<double> _getStock(String itemId, String locationId) async {
    final row = await _client
        .from(_stockLevelsTable)
        .select('quantity')
        .eq('item_id', itemId)
        .eq('location_id', locationId)
        .maybeSingle();
    return row == null ? 0 : _numberValue(row['quantity']);
  }

  Future<Object?> _restoreStock(
    String itemId,
    Map<String, double> previousQuantities,
  ) async {
    try {
      for (final entry in previousQuantities.entries) {
        await _client.from(_stockLevelsTable).upsert({
          'item_id': itemId,
          'location_id': entry.key,
          'quantity': entry.value,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'item_id,location_id');
      }
      return null;
    } catch (error) {
      return error;
    }
  }

  void _validateLocations(
    StockMovementType type,
    String? source,
    String? destination,
  ) {
    switch (type) {
      case StockMovementType.receipt:
      case StockMovementType.returnItem:
        if (destination == null) {
          throw const StockMovementServiceException(
            'Select the destination location.',
          );
        }
      case StockMovementType.issue:
        if (source == null) {
          throw const StockMovementServiceException(
            'Select the source location.',
          );
        }
      case StockMovementType.transfer:
        if (source == null || destination == null) {
          throw const StockMovementServiceException(
            'Select both source and destination locations.',
          );
        }
        if (source == destination) {
          throw const StockMovementServiceException(
            'Source and destination locations must be different.',
          );
        }
    }
  }

  String? _optionalId(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  String _validatedId(String value, String label) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw StockMovementServiceException('Select an $label.');
    }
    return trimmed;
  }

  String? _cleanOptional(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _friendlyMessage(PostgrestException error, String action) {
    if (error.code == '23503') {
      return 'The database rejected a referenced record while trying to '
          '$action. Please verify the item, location, and performer references.';
    }
    if (error.code == '23502') {
      return 'Please complete all required movement fields.';
    }
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

String _requiredString(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('Stock movement is missing required field "$field".');
}

double _numberValue(Object? value) {
  if (value == null) return 0;
  if (value is num && value.isFinite) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed.isFinite) return parsed;
  }
  throw const FormatException('Stock movement contains an invalid quantity.');
}

DateTime? _dateValue(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
