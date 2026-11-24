import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invwise/services/auth_service.dart';
import 'package:invwise/services/login_tracking_service.dart';
import 'package:invwise/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthService.signInWithIdentifier', () {
    test(
      'resolves a valid employee ID before Supabase email authentication',
      () async {
        final harness = _AuthHarness();
        addTearDown(harness.close);
        final service = harness.service();

        final user = await service.signInWithIdentifier(
          identifier: ' EMP-100 ',
          password: 'secret',
        );

        expect(harness.lookedUpEmployeeId, 'EMP-100');
        expect(harness.authEmail, 'employee@example.com');
        expect(user?.email, 'employee@example.com');
      },
    );

    test(
      'rejects an unknown employee ID without attempting authentication',
      () async {
        final harness = _AuthHarness();
        addTearDown(harness.close);
        harness.resolvedEmployeeEmail = null;
        final service = harness.service();

        await expectLater(
          service.signInWithIdentifier(
            identifier: 'UNKNOWN-100',
            password: 'secret',
          ),
          throwsA(
            isA<AuthServiceException>().having(
              (error) => error.message,
              'message',
              'Invalid Employee ID/email or password.',
            ),
          ),
        );

        expect(harness.authEmail, isNull);
      },
    );

    test(
      'keeps email sign-in on the existing Supabase authentication path',
      () async {
        final harness = _AuthHarness();
        addTearDown(harness.close);
        final service = harness.service();

        final user = await service.signInWithIdentifier(
          identifier: ' person@example.com ',
          password: 'secret',
        );

        expect(harness.lookedUpEmployeeId, isNull);
        expect(harness.authEmail, 'person@example.com');
        expect(user?.email, 'person@example.com');
      },
    );

    test(
      'reports incorrect passwords without disclosing account existence',
      () async {
        final harness = _AuthHarness(rejectPassword: true);
        addTearDown(harness.close);
        final service = harness.service();

        await expectLater(
          service.signInWithIdentifier(
            identifier: 'person@example.com',
            password: 'wrong-password',
          ),
          throwsA(
            isA<AuthServiceException>().having(
              (error) => error.message,
              'message',
              'Invalid Employee ID/email or password.',
            ),
          ),
        );

        expect(harness.authEmail, 'person@example.com');
      },
    );
  });
}

class _AuthHarness {
  _AuthHarness({this._rejectPassword = false}) {
    client = SupabaseClient(
      'http://localhost:54321',
      'test-key',
      httpClient: MockClient(_handle),
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: false,
        persistSession: false,
        localStorage: const EmptyLocalStorage(),
      ),
    );
  }

  final bool _rejectPassword;
  late final SupabaseClient client;
  String? authEmail;
  String? lookedUpEmployeeId;
  String? resolvedEmployeeEmail = 'employee@example.com';

  Future<http.Response> _handle(http.Request request) async {
    if (request.url.path.endsWith(
      '/rest/v1/rpc/resolve_login_email_by_employee_id',
    )) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      lookedUpEmployeeId = body['p_employee_id'] as String?;
      return http.Response(
        jsonEncode(resolvedEmployeeEmail),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }
    if (request.url.path.endsWith('/auth/v1/token')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      authEmail = body['email'] as String?;
      if (_rejectPassword) {
        return http.Response(
          jsonEncode({'code': 400, 'message': 'Invalid login credentials'}),
          400,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }
      return http.Response(
        jsonEncode({
          'access_token': 'test-access-token',
          'token_type': 'bearer',
          'expires_in': 3600,
          'refresh_token': 'test-refresh-token',
          'user': {
            'id': '4ee6f289-d74a-4be3-a2d9-b135a78856c2',
            'aud': 'authenticated',
            'role': 'authenticated',
            'email': authEmail,
            'app_metadata': <String, dynamic>{},
            'user_metadata': <String, dynamic>{},
            'created_at': '2026-11-09T00:00:00.000Z',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }
    if (request.url.path.endsWith('/activity_logs')) {
      return http.Response('', 201, request: request);
    }
    return http.Response(
      jsonEncode({'message': 'Unexpected request'}),
      500,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }

  AuthService service() => AuthService(
    client: client,
    loginTrackingService: _TestLoginTrackingService(client),
  );

  void close() {
    client.dispose();
  }
}

class _TestLoginTrackingService extends LoginTrackingService {
  _TestLoginTrackingService(SupabaseClient client)
    : super(
        client: client,
        profileService: ProfileService(client: client),
      );

  @override
  Future<void> recordFailedLogin({
    required String attemptedIdentifier,
    required String failureReason,
  }) async {}

  @override
  Future<void> recordSuccessfulLogin() async {}
}
