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

  test('database role values are recognized', () {
    access.updateRole('Super Admin');
    expect(access.role, AppRole.superAdmin);

    access.updateRole('Inventory Administrator');
    expect(access.role, AppRole.inventoryAdministrator);

    access.updateRole('Warehouse Supervisor');
    expect(access.role, AppRole.warehouseSupervisor);

    access.updateRole('Storekeeper');
    expect(access.role, AppRole.storekeeper);

    for (final unsupportedRole in [
      'IT Administrator',
      'Warehouse Manager',
      'Warehouse Staff',
      'Auditor',
    ]) {
      access.updateRole(unsupportedRole);
      expect(access.role, AppRole.unknown, reason: unsupportedRole);
    }
  });

  test('Super Admin can access all currency controls', () {
    access.updateRole('Super Admin');

    expect(access.allows(AppPermission.viewCurrencySettings), isTrue);
    expect(access.allows(AppPermission.changeDisplayCurrency), isTrue);
    expect(access.allows(AppPermission.manageExchangeRate), isTrue);
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
        AppPermission.bulkChangeCategory,
        AppPermission.bulkChangeWarehouse,
        AppPermission.bulkArchiveInventory,
        AppPermission.bulkDeleteInventory,
        AppPermission.accessPersonalSecurity,
        AppPermission.manageSecurity,
        AppPermission.viewSupportCenter,
      ]) {
        expect(access.allows(permission), isTrue, reason: '$permission');
      }
    },
  );

  test(
    'Warehouse Supervisor can use permitted bulk actions but cannot delete',
    () {
      access.updateRole('Warehouse Supervisor');

      for (final permission in [
        AppPermission.viewDashboard,
        AppPermission.viewSettings,
        AppPermission.viewInventory,
        AppPermission.adjustStock,
        AppPermission.viewReports,
        AppPermission.exportReports,
        AppPermission.manageWarehouses,
        AppPermission.bulkChangeCategory,
        AppPermission.bulkChangeWarehouse,
        AppPermission.bulkArchiveInventory,
        AppPermission.viewAlerts,
        AppPermission.accessPersonalSecurity,
        AppPermission.viewCurrencySettings,
        AppPermission.changeDisplayCurrency,
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
        AppPermission.bulkDeleteInventory,
        AppPermission.manageSecurity,
        AppPermission.viewSupportCenter,
      ]) {
        expect(access.allows(permission), isFalse, reason: '$permission');
      }
    },
  );

  test('Storekeeper can use stock adjustment but no other bulk action', () {
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
      AppPermission.viewCurrencySettings,
      AppPermission.changeDisplayCurrency,
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
      AppPermission.bulkChangeCategory,
      AppPermission.bulkChangeWarehouse,
      AppPermission.bulkArchiveInventory,
      AppPermission.bulkDeleteInventory,
    ]) {
      expect(access.allows(permission), isFalse, reason: '$permission');
    }
  });
}
