import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invwise/features/alerts_page/alerts_page.dart';

void main() {
  testWidgets('Alerts & Tasks is the primary alert page', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AlertsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Alerts & Tasks'), findsOneWidget);
    expect(find.text('URGENT REPLENISHMENT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
