import 'package:supabase_flutter/supabase_flutter.dart';

class UnitServiceException implements Exception {
  const UnitServiceException(this.message);

  final String message;

  @override
  String toString() => 'UnitServiceException: $message';
}

class MeasurementUnit {
  const MeasurementUnit({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String name;
  final String abbreviation;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get label => '$name ($abbreviation)';

  factory MeasurementUnit.fromMap(Map<String, dynamic> map) {
    return MeasurementUnit(
      id: _requiredString(map, 'id'),
      name: _requiredString(map, 'name'),
      abbreviation: _requiredString(map, 'abbreviation'),
      description: map['description'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class UnitService {
  UnitService();

  final SupabaseClient _client = Supabase.instance.client;

  static const String _table = 'units';

  Future<List<MeasurementUnit>> getUnits({bool includeInactive = false}) async {
    try {
      var query = _client.from(_table).select();
      if (!includeInactive) {
        query = query.eq('is_active', true);
      }
      final rows = await query.order('name', ascending: true);
      return rows
          .map<MeasurementUnit>(MeasurementUnit.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw UnitServiceException(_friendlyMessage(e, 'load units'));
    } catch (e) {
      if (e is UnitServiceException) rethrow;
      throw const UnitServiceException(
        'Unable to load units. Please check your connection and try again.',
      );
    }
  }

  Future<void> createUnit({
    required String name,
    required String abbreviation,
    String? description,
  }) async {
    final payload = _validatedPayload(
      name: name,
      abbreviation: abbreviation,
      description: description,
    );

    try {
      await _client.from(_table).insert({...payload, 'is_active': true});
    } on PostgrestException catch (e) {
      throw UnitServiceException(_friendlyMessage(e, 'create the unit'));
    } catch (e) {
      if (e is UnitServiceException) rethrow;
      throw const UnitServiceException(
        'Unable to create the unit. Please check your connection and try again.',
      );
    }
  }

  Future<void> updateUnit({
    required String id,
    required String name,
    required String abbreviation,
    String? description,
    bool? isActive,
  }) async {
    final unitId = _validatedId(id);
    final payload = _validatedPayload(
      name: name,
      abbreviation: abbreviation,
      description: description,
    );
    payload['updated_at'] = DateTime.now().toUtc().toIso8601String();
    if (isActive != null) payload['is_active'] = isActive;

    try {
      final rows = await _client
          .from(_table)
          .update(payload)
          .eq('id', unitId)
          .select('id');
      if (rows.isEmpty) {
        throw const UnitServiceException(
          'Unit not found, or you do not have permission to update it.',
        );
      }
    } on PostgrestException catch (e) {
      throw UnitServiceException(_friendlyMessage(e, 'update the unit'));
    } on UnitServiceException {
      rethrow;
    } catch (e) {
      if (e is UnitServiceException) rethrow;
      throw const UnitServiceException(
        'Unable to update the unit. Please check your connection and try again.',
      );
    }
  }

  Future<void> deleteUnit(String id) async {
    final unitId = _validatedId(id);
    try {
      final rows = await _client
          .from(_table)
          .delete()
          .eq('id', unitId)
          .select('id');
      if (rows.isEmpty) {
        throw const UnitServiceException(
          'Unit not found, or you do not have permission to delete it.',
        );
      }
    } on PostgrestException catch (e) {
      throw UnitServiceException(_friendlyMessage(e, 'delete the unit'));
    } on UnitServiceException {
      rethrow;
    } catch (e) {
      if (e is UnitServiceException) rethrow;
      throw const UnitServiceException(
        'Unable to delete the unit. Please check your connection and try again.',
      );
    }
  }

  Map<String, dynamic> _validatedPayload({
    required String name,
    required String abbreviation,
    String? description,
  }) {
    final trimmedName = name.trim();
    final trimmedAbbreviation = abbreviation.trim();
    if (trimmedName.isEmpty || trimmedAbbreviation.isEmpty) {
      throw const UnitServiceException(
        'Please enter a unit name and abbreviation.',
      );
    }

    final trimmedDescription = description?.trim();
    return {
      'name': trimmedName,
      'abbreviation': trimmedAbbreviation,
      'description': trimmedDescription == null || trimmedDescription.isEmpty
          ? null
          : trimmedDescription,
    };
  }

  String _validatedId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw const UnitServiceException('Unit not found.');
    }
    return trimmed;
  }

  String _friendlyMessage(PostgrestException e, String action) {
    final message = e.message.toLowerCase();
    if (e.code == '23505') {
      return 'A unit with this name or abbreviation already exists.';
    }
    if (e.code == '23503') {
      return 'This unit is used by inventory items and cannot be deleted.';
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
}

String _requiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw FormatException('Unit is missing required field "$key".');
}
