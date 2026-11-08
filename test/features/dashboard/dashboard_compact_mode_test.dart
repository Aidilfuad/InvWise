import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invwise/features/dashboard/data/dashboard_data.dart';
import 'package:invwise/features/dashboard/widgets/attention_required_card.dart';
import 'package:invwise/features/dashboard/widgets/dashboard_section_header.dart';
import 'package:invwise/features/dashboard/widgets/inventory_health_card.dart';
import 'package:invwise/features/dashboard/widgets/inventory_overview_card.dart';
import 'package:invwise/features/dashboard/widgets/kpi_grid.dart';
import 'package:invwise/features/dashboard/widgets/monthly_insights_card.dart';
import 'package:invwise/features/dashboard/widgets/quick_actions_grid.dart';
import 'package:invwise/features/dashboard/widgets/recent_system_activity_card.dart';
import 'package:invwise/services/system_activity_log_service.dart';

void main() {
  testWidgets('compact dashboard cards reduce phone stack height by 30%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fullHeight = await _measureDashboardCardStack(tester, compact: false);
    final compactHeight = await _measureDashboardCardStack(
      tester,
      compact: true,
    );
    final reduction = (fullHeight - compactHeight) / fullHeight;

    // Keep a concrete measurement in test output for regression visibility.
    // ignore: avoid_print
    print(
      'Phone dashboard card stack: full=${fullHeight.toStringAsFixed(0)}px, '
      'compact=${compactHeight.toStringAsFixed(0)}px, '
      'reduction=${(reduction * 100).toStringAsFixed(1)}%',
    );
    expect(reduction, greaterThanOrEqualTo(0.30));
  });
}

Future<double> _measureDashboardCardStack(
  WidgetTester tester, {
  required bool compact,
}) async {
  final data = DashboardData(
    summary: DashboardInventorySummary(
      totalItems: 542,
      totalStockQuantity: 12543,
      lowStockItems: 12,
      outOfStockItems: 3,
      inactiveItems: 15,
      archivedItems: 7,
      warehouseLocations: 4,
    ),
    recentMovements: [],
    recentActivity: [],
    systemActivities: [
      SystemActivityEntry(
        id: 'a1',
        actorName: 'Aidil',
        category: 'Inventory',
        action: 'Stock Adjustment',
        description: 'Updated quantity of item SKU-001.',
        occurredAt: DateTime(2026, 11, 9, 9, 12, 45),
        entityType: 'inventory_item',
      ),
      SystemActivityEntry(
        id: 'a2',
        actorName: 'System',
        category: 'Telemetry',
        action: 'Sensor Offline',
        description: 'The toggle switch stopped reporting.',
        occurredAt: DateTime(2026, 11, 9, 9, 10),
        entityType: 'sensor',
      ),
      SystemActivityEntry(
        id: 'a3',
        actorName: 'Aidil',
        category: 'User Management',
        action: 'Role Changed',
        description: 'Updated a user role.',
        occurredAt: DateTime(2026, 11, 9, 8, 30),
        entityType: 'user',
      ),
    ],
  );
  const width = 350.0;
  final columnKey = ValueKey('dashboard-stack-$compact');

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: Column(
                key: columnKey,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardSectionHeader(
                    title: 'Inventory Overview',
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 6 : 16),
                  InventoryOverviewCard(summary: data, compact: compact),
                  SizedBox(height: compact ? 6 : 16),
                  KpiGrid(stats: data.kpis, compact: compact),
                  SizedBox(height: compact ? 8 : 20),
                  InventoryHealthCard(summary: data.summary, compact: compact),
                  SizedBox(height: compact ? 8 : 20),
                  DashboardSectionHeader(
                    title: 'Attention Required',
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 6 : 16),
                  AttentionRequiredCard(
                    items: data.attentionItems,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 8 : 20),
                  DashboardSectionHeader(
                    title: 'Recent Activity',
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 6 : 16),
                  RecentSystemActivityCard(
                    entries: data.systemActivities,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 8 : 20),
                  DashboardSectionHeader(
                    title: 'Live Inventory Summary',
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 6 : 16),
                  MonthlyInsightsCard(
                    month: 'November 2026',
                    range: 'Current totals',
                    insights: data.insights,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 8 : 20),
                  DashboardSectionHeader(
                    title: 'Quick Actions',
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 6 : 16),
                  QuickActionsGrid(
                    actions: const [
                      QuickActionItem(
                        type: QuickActionType.addItem,
                        label: 'Add Item',
                        subtitle: 'Create a new inventory item',
                        icon: Icons.add_box_outlined,
                      ),
                      QuickActionItem(
                        type: QuickActionType.inventory,
                        label: 'Inventory',
                        subtitle: 'Browse all inventory',
                        icon: Icons.inventory_2_outlined,
                      ),
                      QuickActionItem(
                        type: QuickActionType.reports,
                        label: 'Reports',
                        subtitle: 'Review reports',
                        icon: Icons.bar_chart,
                      ),
                    ],
                    onActionTap: (_) {},
                    compact: compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final height = tester.getSize(find.byKey(columnKey)).height;
  if (compact) {
    expect(find.text('Items: 542'), findsOneWidget);
    expect(find.text('Low: 12'), findsNWidgets(2));
    expect(find.text('OOS: 3'), findsNWidgets(2));
    expect(find.textContaining('Updated quantity'), findsNothing);
  } else {
    expect(find.text('Total Items'), findsNWidgets(2));
    expect(find.text('Inventory records'), findsOneWidget);
    expect(find.textContaining('Updated quantity'), findsOneWidget);
  }
  expect(tester.takeException(), isNull);
  return height;
}
