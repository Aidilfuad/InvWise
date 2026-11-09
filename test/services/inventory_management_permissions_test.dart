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
            expect(jsonDecode(request.body), {
              'p_item_id': itemId,
              'p_force_delete': false,
            });
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

  test(
    'Super Admin can explicitly request Force Delete through the RPC',
    () async {
      access.updateRole('Super Admin');
      final service = InventoryService(
        client: _client(
          MockClient((request) async {
            expect(jsonDecode(request.body), {
              'p_item_id': itemId,
              'p_force_delete': true,
            });
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

      expect(
        await service.deleteItemsPermanently([itemId], forceDelete: true),
        isEmpty,
      );
    },
  );

  test(
    'permanent delete preserves the database history-blocking message',
    () async {
      access.updateRole('Super Admin');
      const message =
          'Cannot permanently delete Valve: it has 2 stock movement record(s) '
          'and 1 stock count record(s).';
      final service = InventoryService(
        client: _client(
          MockClient(
            (request) async => http.Response(
              jsonEncode({
                'code': '23503',
                'message': message,
                'details': null,
                'hint': null,
              }),
              400,
              headers: {'content-type': 'application/json'},
              request: request,
            ),
          ),
        ),
        roleAccess: access,
      );

      expect(await service.deleteItemsPermanently([itemId]), {itemId: message});
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
