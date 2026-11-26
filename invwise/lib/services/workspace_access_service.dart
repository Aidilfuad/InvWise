import 'package:supabase_flutter/supabase_flutter.dart';

const _workspaceRoleOrder = [
  'Super Admin',
  'Director',
  'Inventory Administrator',
  'Factory 1 Manager',
  'Factory 2 Manager',
  'Warehouse Manager',
  'Manager',
  'Supervisor',
  'Production Supervisor',
  'Quality Assurance / QC Supervisor',
  'Maintenance & Automation Lead',
  'Inventory Controller',
  'Warehouse Supervisor',
  'Storekeeper',
  'Viewer',
];

class WorkspaceDepartment {
  const WorkspaceDepartment({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String name;
  final bool isActive;

  factory WorkspaceDepartment.fromMap(Map<String, dynamic> map) =>
      WorkspaceDepartment(
        id: map['id'] as String,
        name: map['name'] as String,
        isActive: map['is_active'] as bool? ?? true,
      );
}

class WorkspaceRole {
  const WorkspaceRole({
    required this.id,
    required this.name,
    this.description,
    this.scope,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? description;
  final String? scope;
  final bool isActive;

  factory WorkspaceRole.fromMap(Map<String, dynamic> map) => WorkspaceRole(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String?,
    scope: map['scope'] as String?,
    isActive: map['is_active'] as bool? ?? true,
  );
}

class RolePermission {
  const RolePermission({
    required this.roleName,
    required this.permissionKey,
    required this.granted,
  });

  final String roleName;
  final String permissionKey;
  final bool granted;

  factory RolePermission.fromMap(Map<String, dynamic> map) => RolePermission(
    roleName: map['role_name'] as String,
    permissionKey: map['permission_key'] as String,
    granted: map['granted'] as bool? ?? false,
  );
}

class WorkspaceAccessService {
  WorkspaceAccessService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<WorkspaceDepartment>> getDepartments() async {
    final rows = await _client
        .from('departments')
        .select('id,name,is_active')
        .eq('is_active', true)
        .order('name');
    return rows
        .map((row) => WorkspaceDepartment.fromMap(row))
        .toList(growable: false);
  }

  Future<List<WorkspaceRole>> getRoles() async {
    final rows = await _client
        .from('custom_roles')
        .select('id,name,description,scope,is_active')
        .eq('is_active', true)
        .order('name');
    final roles = rows
        .map((row) => WorkspaceRole.fromMap(row))
        .toList();
    roles.sort((left, right) {
      final leftIndex = _workspaceRoleOrder.indexOf(left.name);
      final rightIndex = _workspaceRoleOrder.indexOf(right.name);
      final leftRank = leftIndex < 0 ? _workspaceRoleOrder.length : leftIndex;
      final rightRank = rightIndex < 0
          ? _workspaceRoleOrder.length
          : rightIndex;
      return leftRank.compareTo(rightRank);
    });
    return roles;
  }

  Future<List<RolePermission>> getRolePermissions(String roleName) async {
    final rows = await _client
        .from('role_permissions')
        .select('role_name,permission_key,granted')
        .eq('role_name', roleName);
    return rows
        .map((row) => RolePermission.fromMap(row))
        .toList(growable: false);
  }

  Future<void> upsertDepartment({
    required String name,
    String? description,
    bool isActive = true,
  }) async {
    await _client.rpc(
      'upsert_workspace_department',
      params: {
        'p_name': name,
        'p_description': description,
        'p_is_active': isActive,
      },
    );
  }

  Future<void> upsertRole({
    required String name,
    String? description,
    String? scope,
    bool isActive = true,
  }) async {
    await _client.rpc(
      'upsert_workspace_role',
      params: {
        'p_name': name,
        'p_description': description,
        'p_scope': scope,
        'p_is_active': isActive,
      },
    );
  }

  Future<void> setRolePermission({
    required String roleName,
    required String permissionKey,
    required bool granted,
  }) async {
    await _client.rpc(
      'set_role_permission',
      params: {
        'p_role_name': roleName,
        'p_permission_key': permissionKey,
        'p_granted': granted,
      },
    );
  }
}
