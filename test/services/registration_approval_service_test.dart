import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invwise/services/profile_service.dart';
import 'package:invwise/services/registration_approval_service.dart';
import 'package:invwise/services/role_access_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final access = RoleAccessService.instance;
  late Map<String, dynamic> remoteRequest;
  const pendingRequestMap = {
    'id': 'request-id',
    'full_name': 'Test 1',
    'employee_id': 'EMP9999',
    'email': 'fuadaidrus209@gmail.com',
    'department': null,
    'requested_role': 'Storekeeper',
    'status': 'pending',
    'provisioning_status': 'not_started',
    'provisioning_error': null,
    'created_at': '2026-10-30T10:15:00Z',
  };

  setUpAll(() async {
    remoteRequest = Map<String, dynamic>.from(pendingRequestMap);
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test-key',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/registration_requests')) {
          if (request.method == 'GET') {
            final requestedStatus = request.url.queryParameters['status'];
            final status = requestedStatus?.replaceFirst('eq.', '');
            return http.Response(
              remoteRequest['status'] == status
                  ? jsonEncode([remoteRequest])
                  : '[]',
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          if (request.method == 'PATCH') {
            remoteRequest.addAll(
              jsonDecode(request.body) as Map<String, dynamic>,
            );
            return http.Response(
              jsonEncode({'id': remoteRequest['id']}),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
        }
        return http.Response(
          jsonEncode({'message': 'Unexpected request: $request'}),
          500,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
      authOptions: FlutterAuthClientOptions(
        persistSession: false,
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _MemoryAuthStorage(),
      ),
    );
  });

  setUp(() {
    remoteRequest = Map<String, dynamic>.from(pendingRequestMap);
    access.updateRole('Super Admin');
  });

  tearDown(() {
    access.updateRole(null);
  });

  test('parses pending request fields and creation date', () {
    final request = RegistrationRequest.fromMap(pendingRequestMap);

    expect(request.id, 'request-id');
    expect(request.fullName, 'Test 1');
    expect(request.employeeId, 'EMP9999');
    expect(request.email, 'fuadaidrus209@gmail.com');
    expect(request.department, isNull);
    expect(request.requestedRole, 'Storekeeper');
    expect(request.status, RegistrationRequestStatus.pending);
    expect(request.provisioningStatus, 'not_started');
    expect(request.createdAt, DateTime.utc(2026, 10, 30, 10, 15));
  });

  test('parses provisioning status for approved requests', () {
    final request = RegistrationRequest.fromMap({
      ...pendingRequestMap,
      'status': 'approved',
      'provisioning_status': 'failed',
      'provisioning_error': 'Invitation email could not be sent.',
    });

    expect(request.provisioningStatus, 'failed');
    expect(request.provisioningError, 'Invitation email could not be sent.');
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

  test(
    'pending and approved tabs query and display their exact status',
    () async {
      final service = RegistrationApprovalService(roleAccess: access);

      final pending = await service.getPendingRequests();
      expect(pending.map((request) => request.employeeId), ['EMP9999']);
      expect(pending.single.status, RegistrationRequestStatus.pending);
      expect(await service.getApprovedRequests(), isEmpty);
    },
  );

  test('approving a request moves it from pending to approved', () async {
    final service = RegistrationApprovalService(
      profileService: _TestProfileService(
        const ProfileLookupResult(
          id: 'approver-profile-id',
          role: 'Super Admin',
        ),
      ),
      roleAccess: access,
    );

    expect((await service.getPendingRequests()).single.employeeId, 'EMP9999');
    await service.updateRequestStatus(
      requestId: 'request-id',
      status: RegistrationRequestStatus.approved,
    );
    expect(await service.getPendingRequests(), isEmpty);
    expect((await service.getApprovedRequests()).single.employeeId, 'EMP9999');
    expect(remoteRequest['status'], RegistrationRequestStatus.approved.name);
  });
}

class _TestProfileService extends ProfileService {
  _TestProfileService(this.profile);

  final ProfileLookupResult profile;

  @override
  Future<ProfileLookupResult?> getCurrentProfile() async => profile;
}

class _MemoryAuthStorage extends GotrueAsyncStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }
}
