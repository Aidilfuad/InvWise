import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invwise/services/offline_cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cacheDirectory;
  final cache = OfflineCacheService.instance;

  setUpAll(() async {
    cacheDirectory = await Directory.systemTemp.createTemp(
      'invwise_offline_cache_',
    );
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test-key',
      httpClient: MockClient((_) async => http.Response(jsonEncode([]), 200)),
      authOptions: FlutterAuthClientOptions(
        persistSession: false,
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _MemoryAuthStorage(),
      ),
    );
    await cache.initialize(directory: cacheDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await cacheDirectory.delete(recursive: true);
  });

  test('cache is persisted with user-scoped keys', () async {
    await cache.writeList('inventory.items', [
      {'id': 'item-a', 'quantity': 7},
    ], scopeId: 'user-a');
    await cache.writeList('inventory.items', [
      {'id': 'item-b', 'quantity': 2},
    ], scopeId: 'user-b');
    await Hive.close();
    await cache.initialize(directory: cacheDirectory.path);

    expect(await cache.readList('inventory.items', scopeId: 'user-a'), [
      {'id': 'item-a', 'quantity': 7},
    ]);
    expect(await cache.readList('inventory.items', scopeId: 'user-b'), [
      {'id': 'item-b', 'quantity': 2},
    ]);
  });

  test(
    'cached reads return immediately and update after background sync',
    () async {
      final remote = Completer<List<String>>();
      await cache.writeList('test.values', [
        {'value': 'cached'},
      ], scopeId: 'user-a');

      final values = await cache.loadList<String>(
        key: 'test.values',
        scopeId: 'user-a',
        decode: (row) => row['value'] as String,
        encode: (value) => {'value': value},
        fetchRemote: () => remote.future,
      );
      expect(values, ['cached']);

      remote.complete(['updated']);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(await cache.readList('test.values', scopeId: 'user-a'), [
        {'value': 'updated'},
      ]);
    },
  );
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
