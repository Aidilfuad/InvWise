import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invwise/features/inventory/widgets/inventory_summary_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test-key',
      httpClient: MockClient(
        (request) async => http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        ),
      ),
      authOptions: FlutterAuthClientOptions(
        persistSession: false,
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _MemoryAuthStorage(),
      ),
    );
  });

  testWidgets('shows all inventory metrics and formats MYR asset value', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InventorySummaryCard(
            totalSkuCount: 1234,
            totalAssetValue: 125430.5,
            lowStockCount: 12,
            outOfStockCount: 3,
          ),
        ),
      ),
    );

    expect(find.text('Total SKU Count'), findsOneWidget);
    expect(find.text('1,234'), findsOneWidget);
    expect(find.text('Total Asset Value'), findsOneWidget);
    expect(find.text('RM 125,430.50'), findsOneWidget);
    expect(find.text('Low Stock'), findsOneWidget);
    expect(find.text('Out of Stock'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the summary usable at phone, tablet, and desktop widths', (
    tester,
  ) async {
    for (final size in [
      const Size(320, 640),
      const Size(768, 1024),
      const Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(20),
              child: InventorySummaryCard(
                totalSkuCount: 1234,
                totalAssetValue: 125430.5,
                lowStockCount: 12,
                outOfStockCount: 3,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RM 125,430.50'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
