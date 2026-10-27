import 'package:supabase_flutter/supabase_flutter.dart';

/// Error thrown by [CategoryService] with a message that is safe to show in
/// the UI.
class CategoryServiceException implements Exception {
  const CategoryServiceException(this.message);

  final String message;

  @override
  String toString() => 'CategoryServiceException: $message';
}

/// A row of the `categories` table, plus the number of inventory items that
/// reference it through `inventory_items.category_id`.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.createdBy,
    this.itemCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Number of inventory items in this category. 0 when the count is not
  /// available.
  final int itemCount;

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      itemCount: _readItemCount(map['inventory_items']),
    );
  }

  /// PostgREST returns an embedded count as `[{"count": 12}]`.
  static int _readItemCount(Object? embedded) {
    if (embedded is List && embedded.isNotEmpty) {
      final first = embedded.first;
      if (first is Map) {
        final count = first['count'];
        if (count is num) {
          return count.toInt();
        }
      }
    }
    return 0;
  }
}

/// Reads and writes the `categories` table. UI code should use this class
/// instead of calling Supabase directly.
class CategoryService {
  CategoryService();

  final SupabaseClient _client = Supabase.instance.client;

  static const String _table = 'categories';

  static const String _columnsWithCount = '*, inventory_items(count)';
  static const String _columnsPlain = '*';

  /// Returns categories ordered by name, each with its item count.
  ///
  /// Inactive categories are hidden unless [includeInactive] is true.
  /// Item counts need a foreign key from `inventory_items.category_id` to
  /// `categories.id`. If the counted query fails for any database reason, the
  /// plain list is returned instead with [Category.itemCount] set to 0.
  /// Throws [CategoryServiceException] if the request fails.
  Future<List<Category>> getCategories({bool includeInactive = false}) async {
    try {
      final rows = await _fetchCategories(
        _columnsWithCount,
        includeInactive: includeInactive,
      );
      return _toCategories(rows);
    } on PostgrestException {
      // Counts are optional: retry without the embedded count. If this query
      // fails too (for example permissions), its error is reported.
      try {
        final rows = await _fetchCategories(
          _columnsPlain,
          includeInactive: includeInactive,
        );
        return _toCategories(rows);
      } on PostgrestException catch (e) {
        throw CategoryServiceException(_friendlyMessage(e, 'load categories'));
      } catch (_) {
        throw const CategoryServiceException(
          'Unable to load categories. Please check your connection and try '
          'again.',
        );
      }
    } catch (_) {
      throw const CategoryServiceException(
        'Unable to load categories. Please check your connection and try '
        'again.',
      );
    }
  }

  /// Creates a category.
  ///
  /// Throws [CategoryServiceException] on invalid input or failure.
  Future<void> createCategory({
    required String name,
    String? description,
  }) async {
    final trimmedName = _validatedName(name);
    final cleanedDescription = _cleanDescription(description);

    try {
      await _client.from(_table).insert({
        'name': trimmedName,
        'description': cleanedDescription,
      });
    } on PostgrestException catch (e) {
      throw CategoryServiceException(_friendlyMessage(e, 'create the category'));
    } catch (_) {
      throw const CategoryServiceException(
        'Unable to create the category. Please check your connection and try '
        'again.',
      );
    }
  }

  /// Updates the category with [id].
  ///
  /// [name] and [description] are always written; a null or empty
  /// [description] clears it. [isActive] is only written when provided.
  /// Throws [CategoryServiceException] on invalid input or failure.
  Future<void> updateCategory({
    required String id,
    required String name,
    String? description,
    bool? isActive,
  }) async {
    final trimmedId = _validatedId(id);
    final trimmedName = _validatedName(name);
    final cleanedDescription = _cleanDescription(description);

    final payload = <String, dynamic>{
      'name': trimmedName,
      'description': cleanedDescription,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (isActive != null) 'is_active': isActive,
    };

    List<Map<String, dynamic>> rows;

    try {
      rows = await _client
          .from(_table)
          .update(payload)
          .eq('id', trimmedId)
          .select('id');
    } on PostgrestException catch (e) {
      throw CategoryServiceException(_friendlyMessage(e, 'update the category'));
    } catch (_) {
      throw const CategoryServiceException(
        'Unable to update the category. Please check your connection and try '
        'again.',
      );
    }

    // Row Level Security can silently match zero rows instead of failing.
    if (rows.isEmpty) {
      throw const CategoryServiceException(
        'Category not found, or you do not have permission to update it.',
      );
    }
  }

  /// Permanently deletes the category with [id].
  ///
  /// A category that is still used by inventory items cannot be deleted;
  /// deactivate it with [updateCategory] instead.
  /// Throws [CategoryServiceException] on invalid input or failure.
  Future<void> deleteCategory(String id) async {
    final trimmedId = _validatedId(id);

    List<Map<String, dynamic>> rows;

    try {
      rows = await _client
          .from(_table)
          .delete()
          .eq('id', trimmedId)
          .select('id');
    } on PostgrestException catch (e) {
      throw CategoryServiceException(_friendlyMessage(e, 'delete the category'));
    } catch (_) {
      throw const CategoryServiceException(
        'Unable to delete the category. Please check your connection and try '
        'again.',
      );
    }

    if (rows.isEmpty) {
      throw const CategoryServiceException(
        'Category not found, or you do not have permission to delete it.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCategories(
    String columns, {
    required bool includeInactive,
  }) async {
    var query = _client.from(_table).select(columns);

    if (!includeInactive) {
      query = query.eq('is_active', true);
    }

    return await query.order('name', ascending: true);
  }

  List<Category> _toCategories(List<Map<String, dynamic>> rows) {
    return rows
        .map<Category>((row) => Category.fromMap(row))
        .toList(growable: false);
  }

  String _validatedName(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      throw const CategoryServiceException('Please enter a category name.');
    }

    return trimmed;
  }

  String _validatedId(String id) {
    final trimmed = id.trim();

    if (trimmed.isEmpty) {
      throw const CategoryServiceException('Category not found.');
    }

    return trimmed;
  }

  String? _cleanDescription(String? description) {
    final trimmed = description?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  /// Maps a Postgres / PostgREST error to a message safe to show in the UI.
  /// [action] completes "Unable to ...", e.g. "delete the category".
  String _friendlyMessage(PostgrestException e, String action) {
    final code = e.code;
    final message = e.message.toLowerCase();

    if (code == '23505') {
      return 'A category with this name already exists.';
    }
    if (code == '23503') {
      return 'This category is still used by inventory items and cannot be '
          'deleted. Deactivate it instead.';
    }
    if (code == '23502') {
      return 'Please fill in all required fields.';
    }
    if (code == '42501' || message.contains('row-level security')) {
      return 'You do not have permission to $action.';
    }
    if (message.contains('jwt') || code == 'PGRST301') {
      return 'Your session has expired. Please sign in again.';
    }
    return 'Unable to $action. Please try again.';
  }
}