import 'package:flutter_test/flutter_test.dart';
import 'package:invwise/services/user_management_service.dart';

void main() {
  group('ManagedUser', () {
    final user = ManagedUser.fromMap({
      'id': 'profile-1',
      'auth_user_id': 'auth-1',
      'employee_id': 'EMP-01',
      'full_name': 'Alex Example',
      'email': 'alex@example.com',
      'role': 'Warehouse Supervisor',
      'is_active': true,
      'last_login_at': '2026-11-08T10:30:00Z',
      'is_self': false,
    });

    test('parses user details and last login', () {
      expect(user.fullName, 'Alex Example');
      expect(user.role, 'Warehouse Supervisor');
      expect(user.isActive, isTrue);
      expect(user.lastLoginAt, DateTime.utc(2026, 11, 8, 10, 30));
    });

    test('searches name, email, employee ID, and role', () {
      expect(user.matches(query: 'alex'), isTrue);
      expect(user.matches(query: 'EXAMPLE.COM'), isTrue);
      expect(user.matches(query: 'emp-01'), isTrue);
      expect(user.matches(query: 'supervisor'), isTrue);
      expect(user.matches(query: 'missing'), isFalse);
    });

    test('filters by role and account status', () {
      expect(
        user.matches(roleFilter: 'Warehouse Supervisor', activeFilter: true),
        isTrue,
      );
      expect(user.matches(roleFilter: 'Storekeeper'), isFalse);
      expect(user.matches(activeFilter: false), isFalse);
    });
  });
}
