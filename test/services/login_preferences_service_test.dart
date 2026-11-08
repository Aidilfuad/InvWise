import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:invwise/services/auth_service.dart';
import 'package:invwise/services/login_preferences_service.dart';
import 'package:invwise/services/offline_cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => switch (call.method) {
            'getAll' => <String, Object>{},
            'remove' => true,
            _ => null,
          },
        );
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test-key',
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: false,
        persistSession: false,
        localStorage: const EmptyLocalStorage(),
      ),
    );
  });

  setUp(() {
    OfflineCacheService.instance.initializeInMemoryForTesting();
  });

  test(
    'remember me and email persist locally and clear when disabled',
    () async {
      final service = LoginPreferencesService.instance;
      await service.rememberLogin(
        email: 'person@example.com',
        employeeId: 'EMP100',
        enabled: true,
      );
      expect(service.rememberMe, isTrue);
      expect(service.rememberedEmail, 'person@example.com');
      expect(service.rememberedEmployeeId, 'EMP100');

      await service.initialize();
      expect(service.rememberMe, isTrue);
      expect(service.rememberedEmail, 'person@example.com');

      await service.setRememberMe(false);
      expect(service.rememberMe, isFalse);
      expect(service.rememberedEmail, isNull);
      expect(service.rememberedEmployeeId, isNull);
    },
  );

  test('startup requires login without an opted-in valid session', () async {
    final service = LoginPreferencesService.instance;
    final client = Supabase.instance.client;

    expect(await service.prepareForStartup(client), isFalse);
    await service.setRememberMe(true);
    expect(await service.prepareForStartup(client), isFalse);
  });

  test(
    'valid session restoration requires Remember Me and a future expiry',
    () {
      expect(
        LoginPreferencesService.shouldRestoreSession(
          rememberMe: true,
          expiresAt: 2000,
          nowSeconds: 1000,
        ),
        isTrue,
      );
      expect(
        LoginPreferencesService.shouldRestoreSession(
          rememberMe: false,
          expiresAt: 2000,
          nowSeconds: 1000,
        ),
        isFalse,
      );
      expect(
        LoginPreferencesService.shouldRestoreSession(
          rememberMe: true,
          expiresAt: 1000,
          nowSeconds: 1000,
        ),
        isFalse,
      );
    },
  );

  test('logout clears remembered identity and Supabase session', () async {
    final preferences = LoginPreferencesService.instance;
    await preferences.rememberLogin(
      email: 'person@example.com',
      employeeId: 'EMP100',
      enabled: true,
    );

    await AuthService(
      client: Supabase.instance.client,
      loginPreferencesService: preferences,
    ).signOut();

    expect(Supabase.instance.client.auth.currentSession, isNull);
    expect(preferences.rememberedEmail, isNull);
    expect(preferences.rememberedEmployeeId, isNull);
    expect(preferences.rememberMe, isTrue);
  });
}
