import 'package:supabase_flutter/supabase_flutter.dart';

class SystemActivityEntry {
  const SystemActivityEntry({
    required this.id,
    required this.actorName,
    required this.category,
    required this.action,
    required this.description,
    required this.occurredAt,
    required this.entityType,
    this.entityId,
    this.metadata = const {},
  });

  final String id;
  final String actorName;
  final String category;
  final String action;
  final String description;
  final DateTime occurredAt;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic> metadata;

  factory SystemActivityEntry.fromMap(Map<String, dynamic> row) {
    final rawMetadata = row['metadata'];
    return SystemActivityEntry(
      id: row['id'] as String,
      actorName: row['actor_name'] as String? ?? 'System',
      category: row['category'] as String,
      action: row['action'] as String,
      description: row['description'] as String,
      occurredAt: DateTime.parse(row['occurred_at'] as String).toLocal(),
      entityType: row['entity_type'] as String? ?? 'general',
      entityId: row['entity_id'] as String?,
      metadata: rawMetadata is Map
          ? Map<String, dynamic>.from(rawMetadata)
          : const {},
    );
  }

  Map<String, dynamic> toCacheMap() => {
    'id': id,
    'actor_name': actorName,
    'category': category,
    'action': action,
    'description': description,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'entity_type': entityType,
    'entity_id': entityId,
    'metadata': metadata,
  };
}

class SystemActivityLogService {
  SystemActivityLogService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String table = 'activity_logs';

  Future<void> record({
    required String category,
    required String action,
    required String description,
    String entityType = 'general',
    String? entityId,
    Map<String, dynamic> metadata = const {},
    String? actorName,
    String? actorUserId,
  }) async {
    final user = _client.auth.currentUser;
    final name = actorName ?? _actorName(user);
    await _client.from(table).insert({
      'actor_user_id': actorUserId ?? user?.id,
      'actor_name': name,
      'category': category.trim(),
      'action': action.trim(),
      'description': description.trim(),
      'entity_type': entityType.trim(),
      'entity_id': entityId,
      'metadata': metadata,
    });
  }

  Future<List<SystemActivityEntry>> getEntries({
    int limit = 500,
    String? category,
    DateTime? from,
    DateTime? through,
  }) async {
    if (limit <= 0 || limit > 1000) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 1000.');
    }
    var query = _client.from(table).select();
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (from != null) {
      query = query.gte('occurred_at', from.toUtc().toIso8601String());
    }
    if (through != null) {
      final exclusiveEnd = DateTime(
        through.year,
        through.month,
        through.day,
      ).add(const Duration(days: 1));
      query = query.lt('occurred_at', exclusiveEnd.toUtc().toIso8601String());
    }
    final rows = await query
        .order('occurred_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
    return rows
        .map(
          (row) => SystemActivityEntry.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  Future<List<SystemActivityEntry>> getLatest({int limit = 5}) =>
      getEntries(limit: limit);

  static String _actorName(User? user) {
    if (user == null) return 'System';
    final metadata = user.userMetadata;
    final fullName = metadata?['full_name'] ?? metadata?['name'];
    if (fullName is String && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    final email = user.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'User';
  }
}
