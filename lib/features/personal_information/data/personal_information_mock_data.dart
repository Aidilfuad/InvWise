class PersonalInformationData {
  const PersonalInformationData({
    required this.initials,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.department,
    required this.role,
    required this.employeeId,
    required this.warehouseAssignment,
    required this.employmentStatus,
    required this.accessLevel,
    required this.username,
    required this.lastLogin,
    required this.accountCreated,
  });

  final String initials;
  final String fullName;
  final String email;
  final String phone;
  final String department;
  final String role;
  final String employeeId;
  final String warehouseAssignment;
  final String employmentStatus;
  final String accessLevel;
  final String username;
  final String lastLogin;
  final String accountCreated;
}

class PersonalInformationMockData {
  const PersonalInformationMockData._();

  static const PersonalInformationData profile = PersonalInformationData(
    initials: 'AF',
    fullName: 'Aidil Fuad',
    email: 'aidil.fuad@invwise.com',
    phone: '+60 12-345 6789',
    department: 'Inventory Management',
    role: 'Inventory Administrator',
    employeeId: 'INV-001',
    warehouseAssignment: 'Main Warehouse · Shah Alam',
    employmentStatus: 'Active · Full-time',
    accessLevel: 'Administrator',
    username: 'aidil.fuad',
    lastLogin: '25 Oct 2026, 9:32 AM MYT',
    accountCreated: '12 Jan 2025',
  );
}