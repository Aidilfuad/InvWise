import 'package:flutter/material.dart';

import 'profile_service.dart';

enum AppRole {
  inventoryAdministrator,
  warehouseSupervisor,
  storekeeper,
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
  accessPersonalSecurity,
  manageSecurity,
  viewSupportCenter,
}

class RoleAccessService extends ChangeNotifier {
  RoleAccessService._();

  static final RoleAccessService instance = RoleAccessService._();

  late final ProfileService _profileService = ProfileService();
  Future<void>? _pendingLoad;

  AppRole _role = AppRole.unknown;
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _errorMessage;

  AppRole get role => _role;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateRole(String? profileRole) {
    _role = _parseRole(profileRole);
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
      updateRole(profile.role);
    } on ProfileServiceException catch (error) {
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

  bool allows(AppPermission permission) =>
      _permissionsByRole[_role]?.contains(permission) ?? false;

  bool allowsAny(Iterable<AppPermission> permissions) =>
      permissions.any(allows);

  void requirePermission(AppPermission permission) {
    if (!allows(permission)) {
      throw StateError('The current role does not allow $permission.');
    }
  }

  AppRole _parseRole(String? value) {
    final normalized = value?.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return switch (normalized) {
      'inventoryadministrator' => AppRole.inventoryAdministrator,
      'warehousesupervisor' => AppRole.warehouseSupervisor,
      'storekeeper' => AppRole.storekeeper,
      _ => AppRole.unknown,
    };
  }
}

const Set<AppPermission> _inventoryAdministratorPermissions = {
  AppPermission.viewDashboard,
  AppPermission.viewSettings,
  AppPermission.viewInventory,
  AppPermission.createInventory,
  AppPermission.editInventory,
  AppPermission.deleteInventory,
  AppPermission.adjustStock,
  AppPermission.receiveStock,
  AppPermission.issueStock,
  AppPermission.viewReports,
  AppPermission.exportReports,
  AppPermission.viewActivityLog,
  AppPermission.viewAlerts,
  AppPermission.manageCategories,
  AppPermission.manageUnits,
  AppPermission.manageWarehouses,
  AppPermission.accessPersonalSecurity,
  AppPermission.manageSecurity,
  AppPermission.viewSupportCenter,
};

const Set<AppPermission> _dashboardPermissions = {
  AppPermission.viewDashboard,
  AppPermission.viewSettings,
  AppPermission.viewAlerts,
  AppPermission.accessPersonalSecurity,
};

const Set<AppPermission> _warehouseSupervisorPermissions = {
  ..._dashboardPermissions,
  AppPermission.viewInventory,
  AppPermission.adjustStock,
  AppPermission.manageWarehouses,
  AppPermission.viewReports,
  AppPermission.exportReports,
};

const Set<AppPermission> _storekeeperPermissions = {
  ..._dashboardPermissions,
  AppPermission.viewInventory,
  AppPermission.adjustStock,
  AppPermission.receiveStock,
  AppPermission.issueStock,
  AppPermission.viewSupportCenter,
};

const Map<AppRole, Set<AppPermission>> _permissionsByRole = {
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
