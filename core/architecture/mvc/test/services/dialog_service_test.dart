import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvc/mvc.dart';

/// Pumps a minimal app whose root shows `'base'`, with [navigatorKey]
/// attached so an [OverlayDialogService] built from it has a [Navigator] to
/// show dialogs above.
Future<void> _pumpBaseApp(
  WidgetTester tester,
  GlobalKey<NavigatorState> navigatorKey,
) {
  // No `builder:` here deliberately: `WidgetsApp.builder` receives the
  // built Navigator as its `child` argument rather than inserting it
  // automatically, so a `builder` that ignores that argument (as a minimal
  // fixture like this one would) never actually mounts the Navigator, and
  // `navigatorKey` never attaches. Relying on `onGenerateRoute` alone keeps
  // the Navigator as the widget tree's root.
  return tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFFFFFFFF),
      navigatorKey: navigatorKey,
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (_, _, _) =>
            const Text('base', textDirection: TextDirection.ltr),
      ),
    ),
  );
}

void main() {
  group('OverlayDialogService', () {
    testWidgets('show displays the built widget above the app', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final service = OverlayDialogService(navigatorKey);
      await _pumpBaseApp(tester, navigatorKey);

      unawaited(
        service.show<void>(
          (_) => const Text('dialog content', textDirection: TextDirection.ltr),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('dialog content'), findsOneWidget);
    });

    testWidgets('close dismisses the dialog and resolves show with its '
        'result', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final service = OverlayDialogService(navigatorKey);
      await _pumpBaseApp(tester, navigatorKey);

      final resultFuture = service.show<String>(
        (_) => const Text('dialog content', textDirection: TextDirection.ltr),
      );
      await tester.pumpAndSettle();

      service.close<String>('confirmed');
      await tester.pumpAndSettle();

      expect(find.text('dialog content'), findsNothing);
      expect(await resultFuture, 'confirmed');
    });
  });
}
