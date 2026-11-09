import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'role_access_service.dart';
import 'system_activity_log_service.dart';

class UserManagementServiceException implements Exception {
  const UserManagementServiceException(this.message);

  final String message;

  @override
  String toString() => 'UserManagementServiceException: $message';
}

class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.isSelf,
    this.deletionPending = false,
    this.authUserId,
    this.employeeId,
    this.avatarUrl,
    this.lastLoginAt,
  });

  static const List<String> roles = [
    'Super Admin',
    'Inventory Administrator',
    'Warehouse Supervisor',
    'Storekeeper',
  ];

  final String id;
  final String? authUserId;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final bool isSelf;
  final bool deletionPending;
  final String? employeeId;
  final String? avatarUrl;
  final DateTime? lastLoginAt;

  factory ManagedUser.fromMap(Map<String, dynamic> map) {
    final lastLoginValue = map['last_login_at'];
    return ManagedUser(
      id: map['id'] as String,
      authUserId: map['auth_user_id'] as String?,
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String,
      isActive: map['is_active'] as bool,
      isSelf: map['is_self'] as bool? ?? false,
      deletionPending: map['is_deletion_pending'] as bool? ?? false,
      employeeId: map['employee_id'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      lastLoginAt: lastLoginValue is String
          ? DateTime.parse(lastLoginValue)
          : null,
    );
  }

  bool matches({String query = '', String? roleFilter, bool? activeFilter}) {
    final normalizedQuery = query.trim().toLowerCase();
    final textMatches =
        normalizedQuery.isEmpty ||
        [
          fullName,
          email,
          employeeId ?? '',
          role,
        ].any((value) => value.toLowerCase().contains(normalizedQuery));
    return textMatches &&
        (roleFilter == null || role == roleFilter) &&
        (activeFilter == null || isActive == activeFilter);
  }
}

class UserManagementService {
  UserManagementService({SupabaseClient? client, RoleAccessService? roleAccess})
    : _client = client ?? Supabase.instance.client,
      _roleAccess = roleAccess ?? RoleAccessService.instance;

  static const String _functionName = 'manage-users';

  final SupabaseClient _client;
  final RoleAccessService _roleAccess;
  late final SystemActivityLogService _activityLog = SystemActivityLogService(
    client: _client,
  );

  Future<List<ManagedUser>> getUsers() async {
    _requireSuperAdmin();
    final response = await _invoke({'action': 'list'});
    final data = response.data;
    if (data is! Map || data['users'] is! List) {
      throw const UserManagementServiceException(
        'The user management service returned an invalid user list.',
      );
    }
    try {
      return (data['users'] as List)
          .map(
            (row) => ManagedUser.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
    } catch (error) {
      throw UserManagementServiceException(
        'Unable to read user account details. $error',
      );
    }
  }

  Future<void> changeRole({
    required String userId,
    required String role,
    String? userName,
    String? oldRole,
  }) async {
    _requireSuperAdmin();
    if (!ManagedUser.roles.contains(role)) {
      throw const UserManagementServiceException(
        'Select one of the supported user roles.',
      );
    }
    await _invoke({'action': 'change_role', 'user_id': userId, 'role': role});
    try {
      await _activityLog.record(
        category: 'User Management',
        action: 'Changed role',
        description: '${userName ?? userId}: ${oldRole ?? 'Role'} → $role',
        entityType: 'profile',
        entityId: userId,
        metadata: {'old_role': oldRole, 'new_role': role},
      );
    } catch (error) {
      debugPrint(
        '[UserManagementService] Unable to record role change: $error',
      );
    }
  }

  Future<void> setActive({
    required String userId,
    required bool isActive,
    String? userName,
  }) async {
    _requireSuperAdmin();
    await _invoke({
      'action': 'set_active',
      'user_id': userId,
      'is_active': isActive,
    });
    try {
      await _activityLog.record(
        category: 'User Management',
        action: isActive ? 'Activated user' : 'Deactivated user',
        description:
            '${userName ?? userId} was ${isActive ? 'activated' : 'deactivated'}.',
        entityType: 'profile',
        entityId: userId,
        metadata: {'is_active': isActive},
      );
    } catch (error) {
      debugPrint('[UserManagementService] Unable to record activation: $error');
    }
  }

  Future<void> permanentlyDelete({
    required String userId,
  }) async {
    _requireSuperAdmin();
    await _invoke({'action': 'permanent_delete', 'user_id': userId});
  }

  void _requireSuperAdmin() {
    if (!_roleAccess.allows(AppPermission.manageUsers)) {
      throw const UserManagementServiceException(
        'Only a Super Admin can manage user accounts.',
      );
    }
  }

  Future<FunctionResponse> _invoke(Map<String, Object> body) async {
    try {
      return await _client.functions.invoke(_functionName, body: body);
    } on FunctionException catch (error) {
      throw UserManagementServiceException(
        _functionError(error.details) ??
            'User management request failed (HTTP ${error.status}).',
      );
    } catch (error) {
      throw UserManagementServiceException(
        'Unable to contact the user management service. $error',
      );
    }
  }

  String? _functionError(Object? details) {
    if (details is Map) {
      final message = details['error'] ?? details['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }
    }
    if (details is String && details.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map) {
          final message = decoded['error'] ?? decoded['message'];
          if (message != null && message.toString().trim().isNotEmpty) {
            return message.toString().trim();
          }
        }
      } on FormatException {
        return details.trim();
      }
      return details.trim();
    }
    return null;
  }
}
