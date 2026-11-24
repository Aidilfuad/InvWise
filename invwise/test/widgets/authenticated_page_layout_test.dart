import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invwise/widgets/authenticated_page_layout.dart';

void main() {
  testWidgets(
    'authenticated page layout uses responsive gutters and max width',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final size in [
        const Size(390, 844),
        const Size(900, 1000),
        const Size(1920, 1080),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuthenticatedPageLayout(
                child: SizedBox.expand(
                  key: const ValueKey('page-content'),
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final contentWidth = tester
            .getSize(find.byKey(const ValueKey('page-content')))
            .width;
        final expectedWidth = switch (size.width) {
          < 600 => size.width - 24,
          < 1200 => size.width - 40,
          _ => 1536,
        };
        expect(contentWidth, expectedWidth);
        expect(tester.takeException(), isNull);
      }

      addTearDown(tester.view.resetPhysicalSize);
    },
  );

  test(
    'authentication routes are excluded while authenticated routes stretch',
    () {
      final observer = AuthenticatedPageRouteObserver(
        initialAuthenticationRoute: true,
      );
      final loginRoute = _route('/login');
      final dashboardRoute = _route('/dashboard');
      final unnamedRoute = _route(null);
      final registrationRoute = _route('/register');

      observer.didPush(loginRoute, null);
      expect(observer.isAuthenticationRoute.value, isTrue);
      observer.didPush(dashboardRoute, loginRoute);
      expect(observer.isAuthenticationRoute.value, isFalse);
      observer.didPush(unnamedRoute, dashboardRoute);
      expect(observer.isAuthenticationRoute.value, isFalse);
      observer.didPop(unnamedRoute, dashboardRoute);
      expect(observer.isAuthenticationRoute.value, isFalse);
      observer.didPush(registrationRoute, dashboardRoute);
      expect(observer.isAuthenticationRoute.value, isTrue);

      observer.dispose();
    },
  );
}

MaterialPageRoute<void> _route(String? name) => MaterialPageRoute<void>(
  settings: RouteSettings(name: name),
  builder: (_) => const SizedBox.shrink(),
);
