import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invwise/services/inventory_service.dart';
import 'package:invwise/services/role_access_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const itemId = '00000000-0000-4000-8000-000000000001';
  final access = RoleAccessService.instance;

  tearDown(() => access.updateRole(null));

  test(
    'permanent delete is rejected in the client service for administrators',
    () async {
      access.updateRole('Inventory Administrator');
      final service = InventoryService(
        client: _client(MockClient((_) async => http.Response('', 204))),
        roleAccess: access,
      );

      await expectLater(
        service.deleteItemsPermanently([itemId]),
        throwsA(isA<InventoryServiceException>()),
      );
    },
  );

  test(
    'Super Admin permanent delete invokes only the audited database RPC',
    () async {
      access.updateRole('Super Admin');
      var rpcCalled = false;
      final service = InventoryService(
        client: _client(
          MockClient((request) async {
            expect(
              request.url.path,
              endsWith('/rpc/permanently_delete_inventory_item'),
            );
            expect(request.method, 'POST');
            expect(jsonDecode(request.body), {'p_item_id': itemId});
            rpcCalled = true;
            return http.Response(
              jsonEncode({'id': itemId, 'name': 'Valve', 'sku': 'VALVE-1'}),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }),
        ),
        roleAccess: access,
      );

      final failures = await service.deleteItemsPermanently([itemId]);

      expect(rpcCalled, isTrue);
      expect(failures, isEmpty);
    },
  );

  test('archive and restore use database permission-checked RPCs', () async {
    access.updateRole('Inventory Administrator');
    final calls = <String>[];
    final service = InventoryService(
      client: _client(
        MockClient((request) async {
          if (request.url.path.contains('/rpc/')) {
            final function = request.url.path.split('/').last;
            calls.add(function);
            expect(request.method, 'POST');
            expect(jsonDecode(request.body), {'p_item_id': itemId});
          }
          return http.Response('', 204, request: request);
        }),
      ),
      roleAccess: access,
    );

    expect(await service.archiveItems([itemId]), isEmpty);
    expect(await service.restoreItems([itemId]), isEmpty);
    expect(calls, ['archive_inventory_item', 'restore_inventory_item']);
  });
}

SupabaseClient _client(http.Client httpClient) => SupabaseClient(
  'http://localhost:54321',
  'test-key',
  httpClient: httpClient,
  authOptions: FlutterAuthClientOptions(
    autoRefreshToken: false,
    persistSession: false,
    localStorage: const EmptyLocalStorage(),
  ),
);
