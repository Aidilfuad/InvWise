import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invwise/features/inventory/data/item_details_data.dart';
import 'package:invwise/features/inventory/widgets/inventory_summary_card.dart';
import 'package:invwise/features/settings/currency_settings_page.dart';
import 'package:invwise/features/settings/settings_page.dart';
import 'package:invwise/services/currency_service.dart';
import 'package:invwise/services/role_access_service.dart';
import 'package:invwise/services/user_settings_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic>? userSettings;
  late double exchangeRate;
  var missingCurrencyColumn = false;
  const profileId = 'profile-1';

  setUpAll(() async {
    userSettings = null;
    exchangeRate = 4.25;
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test-key',
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/user_settings')) {
          if (request.method == 'GET') {
            if (missingCurrencyColumn) {
              return http.Response(
                jsonEncode({
                  'code': '42703',
                  'message':
                      'column user_settings.currency_code does not exist',
                  'details': null,
                  'hint': null,
                }),
                400,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }
            return http.Response(
              userSettings == null ? '[]' : jsonEncode(userSettings),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          if (request.method == 'POST') {
            final payload = jsonDecode(request.body) as Map<String, dynamic>;
            userSettings = {...?userSettings, ...payload};
            if (request.headers['prefer']?.contains('return=minimal') ??
                false) {
              return http.Response('', 204, request: request);
            }
            return http.Response(
              jsonEncode(userSettings),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
        }
        if (path.endsWith('/app_settings')) {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({'id': true, 'exchange_rate_usd_myr': exchangeRate}),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          if (request.method == 'PATCH') {
            final payload = jsonDecode(request.body) as Map<String, dynamic>;
            exchangeRate = (payload['exchange_rate_usd_myr'] as num).toDouble();
            return http.Response(
              jsonEncode([
                {'exchange_rate_usd_myr': exchangeRate},
              ]),
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
    userSettings = null;
    exchangeRate = 4.25;
    missingCurrencyColumn = false;
    RoleAccessService.instance.updateRole('Super Admin');
  });

  tearDown(() {
    RoleAccessService.instance.updateRole(null);
  });

  test(
    'currency choice and exchange rate persist after service recreation',
    () async {
      final service = _createService();
      await service.loadForProfile(profileId);

      expect(service.currencyCode, 'MYR');
      expect(service.formatMyr(17213), 'RM 17,213.00');

      await service.setDisplayCurrency(
        profileId: profileId,
        currency: DisplayCurrency.usd,
      );
      expect(service.formatMyr(17213), r'$4,050.12');

      await service.setExchangeRateUsdMyr(4.5);
      final reloadedService = _createService();
      await reloadedService.loadForProfile(profileId);

      expect(reloadedService.currencyCode, 'USD');
      expect(reloadedService.exchangeRateUsdMyr, 4.5);
      expect(reloadedService.formatMyr(17213), r'$3,825.11');
      expect(userSettings?['currency_code'], 'USD');
    },
  );

  test('rejects invalid exchange rates and non-admin rate updates', () async {
    final service = _createService();
    await service.loadForProfile(profileId);

    await expectLater(
      service.setExchangeRateUsdMyr(0),
      throwsA(isA<CurrencyServiceException>()),
    );

    RoleAccessService.instance.updateRole('Storekeeper');
    await expectLater(
      service.setExchangeRateUsdMyr(4.3),
      throwsA(isA<CurrencyServiceException>()),
    );
    expect(exchangeRate, 4.25);
  });

  testWidgets('summary and item financial values follow display currency', (
    tester,
  ) async {
    final service = CurrencyService.instance;
    await service.loadForProfile(profileId, refresh: true);
    const item = ItemDetails(
      sku: 'SKU-1',
      name: 'Widget',
      currentStock: 1,
      unit: 'PCS',
      unitPrice: 17213,
      inventoryValue: 17213,
      warehouse: 'Main',
      category: 'General',
      minThreshold: 0,
      description: '',
      notes: '',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InventorySummaryCard(
            totalSkuCount: 1,
            totalAssetValue: 17213,
            lowStockCount: 0,
            outOfStockCount: 0,
          ),
        ),
      ),
    );
    expect(find.text('RM 17,213.00'), findsOneWidget);
    expect(item.unitPriceLabel, 'RM 17,213.00');

    await service.setDisplayCurrency(
      profileId: profileId,
      currency: DisplayCurrency.usd,
    );
    await tester.pump();

    expect(find.text(r'$4,050.12'), findsOneWidget);
    expect(item.unitPriceLabel, r'$4,050.12');
    expect(item.inventoryValueLabel, r'$4,050.12');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'missing database settings fall back without blocking currency UI',
    (tester) async {
      missingCurrencyColumn = true;
      final service = CurrencyService.instance;
      await service.loadForProfile(profileId, refresh: true);

      expect(service.currencyCode, 'MYR');
      expect(service.exchangeRateUsdMyr, 4.25);
      expect(service.errorMessage, contains('does not exist'));

      await tester.pumpWidget(
        const MaterialApp(home: CurrencySettingsPage(profileId: profileId)),
      );
      await tester.pumpAndSettle();

      expect(find.text('MYR'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(
        find.textContaining('Showing the default currency'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Settings page opens when currency settings cannot load', (
    tester,
  ) async {
    missingCurrencyColumn = true;
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Preferences'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

CurrencyService _createService() {
  final client = Supabase.instance.client;
  return CurrencyService(
    client: client,
    userSettingsService: UserSettingsService(client: client),
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
