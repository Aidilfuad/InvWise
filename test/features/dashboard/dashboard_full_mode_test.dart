import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invwise/features/dashboard/data/dashboard_data.dart';
import 'package:invwise/features/dashboard/widgets/full_dashboard_content.dart';
import 'package:invwise/services/system_activity_log_service.dart';

void main() {
  testWidgets('full dashboard fits phone, tablet, and desktop widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [
      const Size(390, 900),
      const Size(800, 1000),
      const Size(1440, 1000),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: _fullDashboard())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inventory Overview'), findsOneWidget);
      expect(find.text('Total Stock Quantity'), findsWidgets);
      expect(find.text('Attention Required'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Live Inventory Summary'), findsOneWidget);
      expect(find.text('Inventory Alerts'), findsNothing);
      expect(find.textContaining('Sensor Monitoring'), findsOneWidget);
      expect(find.text('System Health'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    addTearDown(tester.view.resetPhysicalSize);
  });
}

Widget _fullDashboard() => FullDashboardContent(
  data: DashboardData(
    summary: const DashboardInventorySummary(
      totalItems: 542,
      totalStockQuantity: 12543,
      lowStockItems: 12,
      outOfStockItems: 3,
      warehouseLocations: 4,
      inactiveItems: 15,
      archivedItems: 7,
    ),
    recentMovements: const [],
    recentActivity: const [],
    systemActivities: [
      SystemActivityEntry(
        id: 'a1',
        actorName: 'Aidil',
        category: 'Inventory',
        action: 'Stock Adjustment',
        description: 'Updated quantity of item SKU-001.',
        occurredAt: DateTime(2026, 11, 9, 9, 12),
        entityType: 'inventory_item',
      ),
    ],
  ),
  greeting: 'Good Morning',
  name: 'Aidil Fuad',
  role: 'Inventory Administrator',
  initials: 'AF',
  visibleActions: const [],
  activityPermission: true,
  onNotificationsTap: () {},
  onProfileTap: () {},
  onActivityTap: () {},
  onQuickActionTap: (_) {},
  sensorMonitoring: const Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'Sensor Monitoring\n'
        '2 Sensors\n'
        'DDS669 · Voltage 240V · Current 5.1A · Power 1,224W · Energy 1,450kWh\n'
        'Toggle Switch · ON · Online',
      ),
    ),
  ),
  systemAlerts: const Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('No active system alerts'),
    ),
  ),
);
