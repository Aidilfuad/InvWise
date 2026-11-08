import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invwise/app/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invwise/features/inventory/inventory_page.dart';
import 'package:invwise/services/inventory_service.dart';
import 'package:invwise/services/offline_cache_service.dart';
import 'package:invwise/services/role_access_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var inventoryQueryCount = 0;

  setUpAll(() async {
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test-key',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/inventory_items') ||
            request.url.path.endsWith('/stock_levels')) {
          inventoryQueryCount++;
        }
        final rows = request.url.path.endsWith('/inventory_items')
            ? [
                {
                  'id': 'item-1',
                  'sku': 'SKU-1',
                  'name': 'Widget',
                  'unit_id': 'unit-1',
                  'unit': {'name': 'Piece', 'abbreviation': 'PCS'},
                  'category_id': 'category-1',
                  'category': {'name': 'General'},
                  'minimum_stock': 2,
                  'unit_price': 1.2,
                  'is_active': true,
                },
              ]
            : <Map<String, dynamic>>[];
        return http.Response(
          jsonEncode(rows),
          200,
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
    OfflineCacheService.instance.initializeInMemoryForTesting();
    RoleAccessService.instance.updateRole('Inventory Administrator');
  });

  testWidgets('Inventory layout is responsive with bulk selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const InventoryPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('All Items'), findsOneWidget);
    expect(find.text('Stock Items'), findsOneWidget);
    expect(find.text('Widget'), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpAndSettle();
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('All Items'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CustomScrollView)).height,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    expect(find.text('0 items selected'), findsOneWidget);
    expect(find.text('Select All'), findsOneWidget);
    expect(find.text('Bulk Actions'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Bulk Actions'));
    await tester.pumpAndSettle();
    for (final action in [
      'Change Category',
      'Change Warehouse',
      'Stock Adjustment',
      'Archive Items',
    ]) {
      expect(find.text(action), findsOneWidget);
    }
    expect(find.text('Delete Items'), findsNothing);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select All'));
    await tester.pumpAndSettle();
    expect(find.text('1 item selected'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpAndSettle();
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.ensureVisible(find.text('Bulk Actions'));
    await tester.tap(find.text('Bulk Actions'));
    await tester.pumpAndSettle();
    for (final action in [
      'Change Category',
      'Change Warehouse',
      'Stock Adjustment',
      'Archive Items',
    ]) {
      expect(find.text(action).hitTestable(), findsOneWidget);
    }
    final actionScrollView = tester.widget<SingleChildScrollView>(
      find.ancestor(
        of: find.text('Change Category'),
        matching: find.byType(SingleChildScrollView),
      ),
    );
    expect(actionScrollView.scrollDirection, Axis.vertical);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(CustomScrollView)).height,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(768, 1024);
    await tester.pumpAndSettle();
    expect(find.text('Inventory'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CustomScrollView)).height,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('1 item selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reopening inventory uses the fresh item cache', (tester) async {
    await InventoryService.invalidateItemsCache();
    inventoryQueryCount = 0;
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const InventoryPage()),
    );
    await tester.pumpAndSettle();
    final initialQueryCount = inventoryQueryCount;
    expect(initialQueryCount, greaterThan(0));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const InventoryPage()),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Widget'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpAndSettle();
    expect(inventoryQueryCount, greaterThan(initialQueryCount));
    expect(tester.takeException(), isNull);
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
