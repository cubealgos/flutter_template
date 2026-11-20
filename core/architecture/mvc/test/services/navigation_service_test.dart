import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mvc/mvc.dart';

/// A minimal two-route router (`/home`, `/detail`), each rendering a
/// distinct [Text] so a test can assert on which one is currently showing.
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const Text('home', textDirection: TextDirection.ltr),
      ),
      GoRoute(
        path: '/detail',
        builder: (_, _) =>
            const Text('detail', textDirection: TextDirection.ltr),
      ),
    ],
  );
}

Future<void> _pumpRouter(WidgetTester tester, GoRouter router) {
  return tester.pumpWidget(
    WidgetsApp.router(routerConfig: router, color: const Color(0xFFFFFFFF)),
  );
}

void main() {
  group('GoRouterNavigationService: go/push/pop', () {
    // `router`/`service` are only assignable once per test, from `setUp`
    // (a fresh router per test avoids state leaking between tests) — there
    // is no meaningful non-`late` alternative to this standard test-fixture
    // pattern.
    // ignore: solid_lints/avoid_late_keyword
    late GoRouter router;
    // Same reason as `router` above.
    // ignore: solid_lints/avoid_late_keyword
    late GoRouterNavigationService service;

    setUp(() {
      router = _buildTestRouter();
      service = GoRouterNavigationService(router);
    });

    tearDown(() => router.dispose());

    testWidgets('go navigates to a new location', (tester) async {
      await _pumpRouter(tester, router);
      expect(find.text('home'), findsOneWidget);

      service.go('/detail');
      await tester.pumpAndSettle();

      expect(find.text('detail'), findsOneWidget);
      expect(find.text('home'), findsNothing);
    });

    testWidgets('push adds to the stack; canPop/pop unwind it', (tester) async {
      await _pumpRouter(tester, router);
      expect(service.canPop(), isFalse);

      unawaited(service.push<void>('/detail'));
      await tester.pumpAndSettle();

      expect(find.text('detail'), findsOneWidget);
      expect(service.canPop(), isTrue);

      service.pop();
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(service.canPop(), isFalse);
    });

    testWidgets('pop completes the future returned by push with its result', (
      tester,
    ) async {
      await _pumpRouter(tester, router);

      final resultFuture = service.push<String>('/detail');
      await tester.pumpAndSettle();

      service.pop<String>('picked');
      await tester.pumpAndSettle();

      expect(await resultFuture, 'picked');
    });
  });

  group('GoRouterNavigationService: replace', () {
    // See the ignore reason on the `go/push/pop` group's fields above.
    // ignore: solid_lints/avoid_late_keyword
    late GoRouter router;
    // Same reason as `router` above.
    // ignore: solid_lints/avoid_late_keyword
    late GoRouterNavigationService service;

    setUp(() {
      router = _buildTestRouter();
      service = GoRouterNavigationService(router);
    });

    tearDown(() => router.dispose());

    testWidgets('replace swaps the current location in place', (tester) async {
      await _pumpRouter(tester, router);
      expect(service.canPop(), isFalse);

      unawaited(service.replace<void>('/detail'));
      await tester.pumpAndSettle();

      expect(find.text('detail'), findsOneWidget);
      // A replace does not grow the stack the way push does.
      expect(service.canPop(), isFalse);
    });
  });
}
