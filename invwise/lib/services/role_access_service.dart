import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';

enum AppRole {
  superAdmin,
  director,
  factory1Manager,
  factory2Manager,
  warehouseManager,
  manager,
  supervisor,
  productionSupervisor,
  qualityAssuranceQcSupervisor,
  maintenanceAutomationLead,
  inventoryController,
  inventoryAdministrator,
  warehouseSupervisor,
  storekeeper,
  viewer,
  unknown,
}

enum AppPermission {
  viewDashboard,
  viewSettings,
  viewInventory,
  createInventory,
  editInventory,
  deleteInventory,
  adjustStock,
  receiveStock,
  issueStock,
  viewReports,
  exportReports,
  viewActivityLog,
  viewAlerts,
  manageCategories,
  manageUnits,
  manageWarehouses,
  bulkChangeCategory,
  bulkChangeWarehouse,
  bulkArchiveInventory,
  bulkDeleteInventory,
  restoreArchivedInventory,
  accessPersonalSecurity,
  manageSecurity,
  manageRegistrationRequests,
  viewTelemetry,
  manageTelemetryThresholds,
  viewSupportCenter,
  viewCurrencySettings,
  changeDisplayCurrency,
  manageExchangeRate,
  manageUsers,
}

class RoleAccessService extends ChangeNotifier {
  RoleAccessService._();

  static final RoleAccessService instance = RoleAccessService._();

  late final ProfileService _profileService = ProfileService();
  Future<void>? _pendingLoad;

  AppRole _role = AppRole.unknown;
  String _roleName = '';
  Set<AppPermission> _dynamicPermissions = const {};
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _errorMessage;

  AppRole get role => _role;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get roleName => _roleName;
  bool _dynamicPermissionsLoaded = false;

  void updateRole(String? profileRole) {
    _role = _parseRole(profileRole);
    _roleName = profileRole?.trim() ?? '';
    _dynamicPermissionsLoaded = false;
    _dynamicPermissions = const {};
    _isLoaded = true;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadCurrentRole({bool refresh = false}) {
    if (!refresh && _isLoaded) return Future<void>.value();
    final pendingLoad = _pendingLoad;
    if (pendingLoad != null) return pendingLoad;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final load = _loadCurrentRole();
    _pendingLoad = load;
    return load.whenComplete(() => _pendingLoad = null);
  }

  Future<void> _loadCurrentRole() async {
    try {
      final profile = await _profileService.getCurrentProfile();
      if (profile == null) {
        throw const ProfileServiceException(
          'No profile is linked to the signed-in user.',
        );
      }
      if (!profile.isActive) {
        throw const ProfileServiceException(
          'This account is inactive. Contact a Super Admin.',
        );
      }
      updateRole(profile.role);
      await _loadDynamicPermissions(profile.role);
    } on ProfileServiceException catch (error) {
      _role = AppRole.unknown;
      _isLoaded = true;
      _isLoading = false;
      _errorMessage = error.message;
      notifyListeners();
      rethrow;
    } catch (error) {
      _isLoaded = true;
      _isLoading = false;
      _errorMessage = 'Unable to load your role: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadDynamicPermissions(String? roleName) async {
    if (roleName == null || roleName.trim().isEmpty) return;
    try {
      final rows = await Supabase.instance.client
          .from('role_permissions')
          .select('permission_key,granted')
          .eq('role_name', roleName)
          .eq('granted', true);
      final permissions = <AppPermission>{};
      for (final row in rows) {
        final key = row['permission_key'] as String?;
        final permission = _permissionForKey(key);
        if (permission != null) permissions.add(permission);
      }
      _dynamicPermissions = permissions;
      _dynamicPermissionsLoaded = true;
      notifyListeners();
    } catch (_) {
      _dynamicPermissions = const {};
      _dynamicPermissionsLoaded = true;
      notifyListeners();
    }
  }

  bool allows(AppPermission permission) {
    if (_mandatoryPermissions.contains(permission)) return true;
    if (_role == AppRole.superAdmin ||
        _normalizeRoleName(_roleName) == 'superadmin') {
      return true;
    }
    if (_dynamicPermissionsLoaded) {
      return _dynamicPermissions.contains(permission);
    }
    return _permissionsByRole[_role]?.contains(permission) ?? false;
  }

  bool allowsAny(Iterable<AppPermission> permissions) =>
      permissions.any(allows);

  void requirePermission(AppPermission permission) {
    if (!allows(permission)) {
      throw StateError('The current role does not allow $permission.');
    }
  }

  AppRole _parseRole(String? value) {
    final normalized = _normalizeRoleName(value);
    return switch (normalized) {
      'superadmin' => AppRole.superAdmin,
      'director' => AppRole.director,
      'factory1manager' => AppRole.factory1Manager,
      'factory2manager' => AppRole.factory2Manager,
      'warehousemanager' => AppRole.warehouseManager,
      'manager' => AppRole.manager,
      'supervisor' => AppRole.supervisor,
      'productionsupervisor' => AppRole.productionSupervisor,
      'qualityassuranceqcsupervisor' => AppRole.qualityAssuranceQcSupervisor,
      'maintenanceautomationlead' => AppRole.maintenanceAutomationLead,
      'inventorycontroller' => AppRole.inventoryController,
      'inventoryadministrator' => AppRole.inventoryAdministrator,
      'warehousesupervisor' => AppRole.warehouseSupervisor,
      'storekeeper' => AppRole.storekeeper,
      'viewer' => AppRole.viewer,
      _ => AppRole.unknown,
    };
  }

  String _normalizeRoleName(String? value) =>
      value?.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '') ?? '';

  AppPermission? _permissionForKey(String? key) => switch (key) {
    'view_dashboard' => AppPermission.viewDashboard,
    'view_inventory' => AppPermission.viewInventory,
    'create_inventory' => AppPermission.createInventory,
    'edit_inventory' => AppPermission.editInventory,
    'delete_inventory' => AppPermission.deleteInventory,
    'adjust_stock' => AppPermission.adjustStock,
    'receive_stock' => AppPermission.receiveStock,
    'issue_stock' => AppPermission.issueStock,
    'view_activity' => AppPermission.viewActivityLog,
    'view_alerts' => AppPermission.viewAlerts,
    'view_reports' => AppPermission.viewReports,
    'export_reports' => AppPermission.exportReports,
    'view_telemetry' => AppPermission.viewTelemetry,
    'manage_telemetry_thresholds' => AppPermission.manageTelemetryThresholds,
    'manage_users' => AppPermission.manageUsers,
    'manage_registration_requests' => AppPermission.manageRegistrationRequests,
    'manage_settings' => AppPermission.manageSecurity,
    'manage_departments' => AppPermission.manageUsers,
    'manage_roles' => AppPermission.manageUsers,
    'manage_categories' => AppPermission.manageCategories,
    'manage_units' => AppPermission.manageUnits,
    'manage_warehouses' => AppPermission.manageWarehouses,
    _ => null,
  };
}

const Set<AppPermission> _mandatoryPermissions = {
  AppPermission.viewSettings,
  AppPermission.viewInventory,
  AppPermission.viewReports,
  AppPermission.viewActivityLog,
  AppPermission.viewAlerts,
  AppPermission.viewTelemetry,
};

const Set<AppPermission> _inventoryAdministratorPermissions = {
  AppPermission.viewDashboard,
  AppPermission.viewSettings,
  AppPermission.viewInventory,
  AppPermission.createInventory,
  AppPermission.editInventory,
  AppPermission.adjustStock,
  AppPermission.receiveStock,
  AppPermission.issueStock,
  AppPermission.viewReports,
  AppPermission.exportReports,
  AppPermission.viewActivityLog,
  AppPermission.viewAlerts,
  AppPermission.viewTelemetry,
  AppPermission.manageCategories,
  AppPermission.manageUnits,
  AppPermission.manageWarehouses,
  AppPermission.bulkChangeCategory,
  AppPermission.bulkChangeWarehouse,
  AppPermission.bulkArchiveInventory,
  AppPermission.restoreArchivedInventory,
  AppPermission.accessPersonalSecurity,
  AppPermission.manageSecurity,
  AppPermission.manageRegistrationRequests,
  AppPermission.viewSupportCenter,
  AppPermission.viewCurrencySettings,
  AppPermission.changeDisplayCurrency,
};

const Set<AppPermission> _dashboardPermissions = {
  AppPermission.viewDashboard,
  AppPermission.viewSettings,
  AppPermission.viewAlerts,
  AppPermission.accessPersonalSecurity,
};

const Set<AppPermission> _warehouseSupervisorPermissions = {
  ..._dashboardPermissions,
  AppPermission.viewCurrencySettings,
  AppPermission.changeDisplayCurrency,
  AppPermission.viewInventory,
  AppPermission.adjustStock,
  AppPermission.manageWarehouses,
  AppPermission.bulkChangeCategory,
  AppPermission.bulkChangeWarehouse,
  AppPermission.viewReports,
  AppPermission.exportReports,
  AppPermission.viewTelemetry,
};

const Set<AppPermission> _storekeeperPermissions = {
  ..._dashboardPermissions,
  AppPermission.viewCurrencySettings,
  AppPermission.changeDisplayCurrency,
  AppPermission.viewInventory,
  AppPermission.adjustStock,
  AppPermission.receiveStock,
  AppPermission.issueStock,
  AppPermission.viewSupportCenter,
};

const Map<AppRole, Set<AppPermission>> _permissionsByRole = {
  AppRole.superAdmin: {...AppPermission.values},
  AppRole.inventoryAdministrator: _inventoryAdministratorPermissions,
  AppRole.warehouseSupervisor: _warehouseSupervisorPermissions,
  AppRole.storekeeper: _storekeeperPermissions,
};

class RoleAccessGuard extends StatefulWidget {
  const RoleAccessGuard({
    super.key,
    required this.permission,
    this.additionalPermissions = const {},
    required this.child,
  });

  final AppPermission permission;
  final Set<AppPermission> additionalPermissions;
  final Widget child;

  @override
  State<RoleAccessGuard> createState() => _RoleAccessGuardState();
}

class _RoleAccessGuardState extends State<RoleAccessGuard> {
  final RoleAccessService _access = RoleAccessService.instance;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _ensureRoleLoaded();
  }

  Future<void> _ensureRoleLoaded() async {
    if (_access.isLoaded) return;
    try {
      await _access.loadCurrentRole();
    } on ProfileServiceException catch (error) {
      _loadError = error.message;
    } catch (error) {
      _loadError = 'Unable to verify your role: $error';
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_access.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final error = _loadError ?? _access.errorMessage;
    if (error != null) {
      return _AccessDeniedPage(
        message: 'Unable to verify access. $error',
        onRetry: () {
          setState(() => _loadError = null);
          _access
              .loadCurrentRole(refresh: true)
              .then((_) {
                if (mounted) setState(() {});
              })
              .catchError((Object error) {
                if (mounted) setState(() => _loadError = '$error');
              });
        },
      );
    }
    if (!_access.allows(widget.permission) &&
        !widget.additionalPermissions.any(_access.allows)) {
      return const _AccessDeniedPage(
        message: 'Your role does not have permission to access this page.',
      );
    }
    return widget.child;
  }
}

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Access restricted'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 40),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
