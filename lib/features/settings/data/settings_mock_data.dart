/// Dummy data for the Settings screen.
/// Replace with real user / app info when the backend is connected.

class SettingsProfile {
  const SettingsProfile({
    required this.name,
    required this.role,
    required this.accessLabel,
    required this.initials,
    required this.employeeId,
    required this.email,
    required this.phone,
    required this.department,
  });

  final String name;
  final String role;
  final String accessLabel;
  final String initials;
  final String employeeId;
  final String email;
  final String phone;
  final String department;
}

abstract final class SettingsMockData {
  static const SettingsProfile profile = SettingsProfile(
    name: 'Aidil Fuad',
    role: 'Inventory Administrator',
    accessLabel: 'Admin Access',
    initials: 'AF',
    employeeId: 'INV-001',
    email: 'aidil.fuad@invwise.com',
    phone: '+60 12-345 6789',
    department: 'Inventory Management',
  );

  static const String warehouseLocation = 'North Sector A-12';
  static const String language = 'English (US)';
  static const String appVersion = 'Version 2.4.0-build.88';
}