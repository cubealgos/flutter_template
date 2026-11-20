import 'package:app/app/app.dart';
import 'package:app/app/di.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'critical flow: Settings > Legal is reachable in <=2 taps from the '
    'sign-in screen, pre-login',
    (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Bootstrap resolves to sign-in with no session — this whole flow
      // happens before any login.
      expect(find.text(t.signIn.title), findsOneWidget);

      // Tap 1: the "Legal" link on the sign-in screen.
      await tester.tap(find.text(t.common.legalLink));
      await tester.pumpAndSettle();

      expect(find.text(t.legal.title), findsOneWidget);
      expect(find.text(t.legal.impressum), findsOneWidget);

      // Tap 2: a specific legal document from the hub — `push`, not
      // `go`, so the hub stays in the stack below; the document screen's
      // own template-notice banner (unique to it) confirms we arrived.
      await tester.tap(find.text(t.legal.impressum));
      await tester.pumpAndSettle();

      expect(find.text(t.legal.document.templateNotice), findsOneWidget);
    },
  );
}
