import 'package:flutter/material.dart';

import '../services/workspace_access_service.dart';
import 'searchable_dropdown_form_field.dart';

class RolePermissionManager extends StatefulWidget {
  const RolePermissionManager({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<RolePermissionManager> createState() => _RolePermissionManagerState();
}

class _RolePermissionManagerState extends State<RolePermissionManager>
    with SingleTickerProviderStateMixin {
  final _access = WorkspaceAccessService();
  final _roleName = TextEditingController();
  final _roleDescription = TextEditingController();
  final _roleScope = TextEditingController();
  final _departmentName = TextEditingController();
  final _departmentDescription = TextEditingController();
  late final TabController _tabs = TabController(length: 3, vsync: this);

  List<WorkspaceRole> _roles = const [];
  List<WorkspaceDepartment> _departments = const [];
  Map<String, bool> _draftPermissions = const {};
  final Set<String> _initialRolePermissions = {
    'view_dashboard',
    'view_inventory',
    'view_alerts',
  };
  String? _selectedRole;
  bool _loading = true;
  String? _error;

  static const _permissionLabels = <String, String>{
    'view_dashboard': 'View dashboard',
    'view_inventory': 'View inventory',
    'create_inventory': 'Create inventory',
    'edit_inventory': 'Edit inventory',
    'delete_inventory': 'Delete inventory',
    'adjust_stock': 'Adjust stock',
    'receive_stock': 'Receive stock',
    'issue_stock': 'Issue stock',
    'view_activity': 'View activity',
    'view_alerts': 'View alerts',
    'view_reports': 'View reports',
    'export_reports': 'Export reports',
    'view_telemetry': 'View telemetry',
    'manage_telemetry_thresholds': 'Manage telemetry thresholds',
    'manage_users': 'Manage users',
    'manage_registration_requests': 'Manage registrations',
    'manage_settings': 'Manage settings',
    'manage_departments': 'Manage departments',
    'manage_roles': 'Manage roles',
    'manage_categories': 'Manage categories',
    'manage_units': 'Manage units',
    'manage_warehouses': 'Manage warehouses',
  };

  @override
  void initState() {
    super.initState();
    _tabs.index = widget.initialTab < 0
        ? 0
        : widget.initialTab > 2
        ? 2
        : widget.initialTab;
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _roleName.dispose();
    _roleDescription.dispose();
    _roleScope.dispose();
    _departmentName.dispose();
    _departmentDescription.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roles = await _access.getRoles();
      final departments = await _access.getDepartments();
      final selected =
          _selectedRole ?? (roles.isNotEmpty ? roles.first.name : null);
      final permissions = selected == null
          ? const <RolePermission>[]
          : await _access.getRolePermissions(selected);
      if (!mounted) return;
      setState(() {
        _roles = roles;
        _departments = departments;
        _selectedRole = selected;
        _draftPermissions = {
          for (final entry in _permissionLabels.keys)
            entry:
                (selected ?? '').toLowerCase().replaceAll(
                      RegExp(r'[^a-z]'),
                      '',
                    ) ==
                    'superadmin' ||
                permissions.any(
                  (permission) =>
                      permission.permissionKey == entry && permission.granted,
                ),
        };
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load access settings: $error';
        _loading = false;
      });
    }
  }

  bool _isGranted(String key) =>
      _isSuperAdminSelected || (_draftPermissions[key] ?? false);

  bool get _isSuperAdminSelected {
    final normalized = (_selectedRole ?? '').toLowerCase().replaceAll(
      RegExp(r'[^a-z]'),
      '',
    );
    return normalized == 'superadmin';
  }

  Future<void> _saveRole() async {
    if (_roleName.text.trim().isEmpty) return;
    try {
      await _access.upsertRole(
        name: _roleName.text,
        description: _roleDescription.text,
        scope: _roleScope.text,
      );
      for (final permissionKey in _initialRolePermissions) {
        await _access.setRolePermission(
          roleName: _roleName.text.trim(),
          permissionKey: permissionKey,
          granted: true,
        );
      }
      _roleName.clear();
      _roleDescription.clear();
      _roleScope.clear();
      await _load();
    } catch (error) {
      setState(() => _error = 'Unable to save role: $error');
    }
  }

  Future<void> _saveDepartment() async {
    if (_departmentName.text.trim().isEmpty) return;
    try {
      await _access.upsertDepartment(
        name: _departmentName.text,
        description: _departmentDescription.text,
      );
      _departmentName.clear();
      _departmentDescription.clear();
      await _load();
    } catch (error) {
      setState(() => _error = 'Unable to save department: $error');
    }
  }

  Future<void> _togglePermission(String key, bool granted) async {
    final role = _selectedRole;
    if (role == null || _isSuperAdminSelected) return;
    setState(() => _draftPermissions[key] = granted);
  }

  Future<void> _applyPermissions() async {
    final role = _selectedRole;
    if (role == null || _isSuperAdminSelected) return;
    try {
      for (final entry in _draftPermissions.entries) {
        await _access.setRolePermission(
          roleName: role,
          permissionKey: entry.key,
          granted: entry.value,
        );
      }
      await _load();
    } catch (error) {
      setState(() => _error = 'Unable to update permission: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role & access management'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Permissions'),
            Tab(text: 'Roles'),
            Tab(text: 'Departments'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [_permissionsTab(), _rolesTab(), _departmentsTab()],
            ),
    );
  }

  Widget _permissionsTab() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (_error != null)
        Text(_error!, style: const TextStyle(color: Colors.red)),
      SearchableDropdownFormField(
        initialValue: _selectedRole,
        decoration: const InputDecoration(
          labelText: 'Role',
          border: OutlineInputBorder(),
        ),
        options: _roles.map((role) => role.name).toList(growable: false),
        onChanged: (value) {
          setState(() => _selectedRole = value);
          if (value != null) _load();
        },
      ),
      const SizedBox(height: 12),
      for (final entry in _permissionLabels.entries)
        SwitchListTile(
          title: Text(entry.value),
          value: _isGranted(entry.key),
          onChanged: _isSuperAdminSelected
              ? null
              : (value) => _togglePermission(entry.key, value),
        ),
      if (!_isSuperAdminSelected) ...[
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _applyPermissions,
          child: const Text('Apply Permission Changes'),
        ),
      ],
    ],
  );

  Widget _rolesTab() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (_error != null)
        Text(_error!, style: const TextStyle(color: Colors.red)),
      TextField(
        controller: _roleName,
        decoration: const InputDecoration(
          labelText: 'Role name',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _roleDescription,
        decoration: const InputDecoration(
          labelText: 'Description',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _roleScope,
        decoration: const InputDecoration(
          labelText: 'Scope',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Initial permissions',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      for (final entry in _permissionLabels.entries)
        CheckboxListTile(
          title: Text(entry.value),
          value: _initialRolePermissions.contains(entry.key),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _initialRolePermissions.add(entry.key);
              } else {
                _initialRolePermissions.remove(entry.key);
              }
            });
          },
        ),
      FilledButton(onPressed: _saveRole, child: const Text('Save role')),
      const Divider(height: 32),
      for (final role in _roles)
        ListTile(
          title: Text(role.name),
          subtitle: Text(role.description ?? role.scope ?? 'No description'),
        ),
    ],
  );

  Widget _departmentsTab() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (_error != null)
        Text(_error!, style: const TextStyle(color: Colors.red)),
      TextField(
        controller: _departmentName,
        decoration: const InputDecoration(
          labelText: 'Department name',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _departmentDescription,
        decoration: const InputDecoration(
          labelText: 'Description',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: _saveDepartment,
        child: const Text('Save department'),
      ),
      const Divider(height: 32),
      for (final department in _departments)
        ListTile(
          title: Text(department.name),
          subtitle: Text(department.isActive ? 'Active' : 'Inactive'),
        ),
    ],
  );
}
