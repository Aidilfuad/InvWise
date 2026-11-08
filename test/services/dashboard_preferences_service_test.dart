import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invwise/services/dashboard_preferences_service.dart';
import 'package:invwise/services/offline_cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final preferences = DashboardPreferencesService.instance;
  final cache = OfflineCacheService.instance;

  setUpAll(() async {
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
  });

  setUp(() {
    cache.initializeInMemoryForTesting();
  });

  test('dashboard mode persists and defaults to full mode', () async {
    await preferences.loadForProfile('profile-1');
    expect(preferences.mode, DashboardMode.full);
    expect(preferences.compactCards, isFalse);

    await preferences.setMode(DashboardMode.compact);
    expect(preferences.mode, DashboardMode.compact);
    await preferences.loadForProfile('profile-1');
    expect(preferences.mode, DashboardMode.compact);

    await preferences.setMode(DashboardMode.full);
    await preferences.loadForProfile('profile-1');
    expect(preferences.mode, DashboardMode.full);
  });
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
