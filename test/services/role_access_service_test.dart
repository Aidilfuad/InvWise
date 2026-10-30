import 'package:flutter_test/flutter_test.dart';
import 'package:invwise/services/role_access_service.dart';

void main() {
  final access = RoleAccessService.instance;

  tearDown(() {
    access.updateRole(null);
  });

  test('unknown and missing roles are denied by default', () {
    access.updateRole(null);
    for (final permission in AppPermission.values) {
      expect(access.allows(permission), isFalse);
    }

    access.updateRole('Auditor');
    expect(access.allows(AppPermission.viewDashboard), isFalse);
  });

  test('only the database role values are recognized', () {
    access.updateRole('Inventory Administrator');
    expect(access.role, AppRole.inventoryAdministrator);

    access.updateRole('Warehouse Supervisor');
    expect(access.role, AppRole.warehouseSupervisor);

    access.updateRole('Storekeeper');
    expect(access.role, AppRole.storekeeper);

    for (final unsupportedRole in [
      'Super Admin',
      'IT Administrator',
      'Warehouse Manager',
      'Warehouse Staff',
      'Auditor',
    ]) {
      access.updateRole(unsupportedRole);
      expect(access.role, AppRole.unknown, reason: unsupportedRole);
    }
  });

  test(
    'Inventory Administrator has full inventory and configuration access',
    () {
      access.updateRole('Inventory Administrator');

      for (final permission in [
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
      ]) {
        expect(access.allows(permission), isTrue, reason: '$permission');
      }
    },
  );

  test('Warehouse Supervisor has dashboard, inventory, warehouse, report, '
      'and stock adjustment permissions only', () {
    access.updateRole('Warehouse Supervisor');

    for (final permission in [
      AppPermission.viewDashboard,
      AppPermission.viewSettings,
      AppPermission.viewInventory,
      AppPermission.adjustStock,
      AppPermission.viewReports,
      AppPermission.exportReports,
      AppPermission.manageWarehouses,
      AppPermission.viewAlerts,
      AppPermission.accessPersonalSecurity,
    ]) {
      expect(access.allows(permission), isTrue, reason: '$permission');
    }

    for (final permission in [
      AppPermission.createInventory,
      AppPermission.editInventory,
      AppPermission.deleteInventory,
      AppPermission.receiveStock,
      AppPermission.issueStock,
      AppPermission.viewActivityLog,
      AppPermission.manageCategories,
      AppPermission.manageUnits,
      AppPermission.manageSecurity,
      AppPermission.viewSupportCenter,
    ]) {
      expect(access.allows(permission), isFalse, reason: '$permission');
    }
  });

  test('Storekeeper can view inventory, receive, issue, adjust, and access '
      'support but cannot configure or export', () {
    access.updateRole('Storekeeper');

    for (final permission in [
      AppPermission.viewDashboard,
      AppPermission.viewSettings,
      AppPermission.viewInventory,
      AppPermission.adjustStock,
      AppPermission.receiveStock,
      AppPermission.issueStock,
      AppPermission.viewAlerts,
      AppPermission.accessPersonalSecurity,
      AppPermission.viewSupportCenter,
    ]) {
      expect(access.allows(permission), isTrue, reason: '$permission');
    }

    for (final permission in [
      AppPermission.createInventory,
      AppPermission.editInventory,
      AppPermission.deleteInventory,
      AppPermission.viewReports,
      AppPermission.exportReports,
      AppPermission.viewActivityLog,
      AppPermission.manageCategories,
      AppPermission.manageUnits,
      AppPermission.manageWarehouses,
      AppPermission.manageSecurity,
    ]) {
      expect(access.allows(permission), isFalse, reason: '$permission');
    }
  });
}
