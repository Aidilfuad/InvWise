import 'package:flutter_test/flutter_test.dart';
import 'package:invwise/services/registration_approval_service.dart';

void main() {
  const pendingRequestMap = {
    'id': 'request-id',
    'full_name': 'Alex Example',
    'employee_id': 'EMP-001',
    'email': 'alex@example.com',
    'department': 'Operations',
    'requested_role': 'Storekeeper',
    'status': 'pending',
    'created_at': '2026-10-30T10:15:00Z',
  };

  test('parses pending request fields and creation date', () {
    final request = RegistrationRequest.fromMap(pendingRequestMap);

    expect(request.id, 'request-id');
    expect(request.fullName, 'Alex Example');
    expect(request.employeeId, 'EMP-001');
    expect(request.email, 'alex@example.com');
    expect(request.department, 'Operations');
    expect(request.requestedRole, 'Storekeeper');
    expect(request.status, RegistrationRequestStatus.pending);
    expect(request.createdAt, DateTime.utc(2026, 10, 30, 10, 15));
  });

  test('parses approved and rejected statuses', () {
    final approved = RegistrationRequest.fromMap({
      ...pendingRequestMap,
      'status': 'approved',
    });
    final rejected = RegistrationRequest.fromMap({
      ...pendingRequestMap,
      'status': 'rejected',
    });

    expect(approved.status, RegistrationRequestStatus.approved);
    expect(rejected.status, RegistrationRequestStatus.rejected);
  });

  test('rejects unknown status values', () {
    expect(
      () => RegistrationRequest.fromMap({
        ...pendingRequestMap,
        'status': 'unknown',
      }),
      throwsA(isA<RegistrationApprovalServiceException>()),
    );
  });
}
