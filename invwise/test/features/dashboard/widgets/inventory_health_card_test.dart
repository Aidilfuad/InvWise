import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invwise/features/dashboard/data/dashboard_data.dart';
import 'package:invwise/features/dashboard/widgets/inventory_health_card.dart';

void main() {
  testWidgets('shows inventory counts and computed health score', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InventoryHealthCard(
            summary: DashboardInventorySummary(
              totalItems: 542,
              totalStockQuantity: 1000,
              lowStockItems: 12,
              outOfStockItems: 3,
              inactiveItems: 15,
              archivedItems: 7,
              warehouseLocations: 2,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Inventory Health'), findsOneWidget);
    expect(find.text('Total Items: 542'), findsOneWidget);
    expect(find.text('Low Stock: 12'), findsOneWidget);
    expect(find.text('Out Of Stock: 3'), findsOneWidget);
    expect(find.text('Inactive: 15'), findsOneWidget);
    expect(find.text('Archived: 7'), findsOneWidget);
    expect(find.text('Health Score: 97%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
