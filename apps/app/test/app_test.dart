import 'package:app/app/app.dart';
import 'package:app/app/di.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:auth/auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('critical flow: sign-in (email + OTP) leads to onboarding, not '
      'straight to Home — the fake backend, on by default with no '
      'dart-defines, never touches a real Appwrite instance', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Bootstrap resolves straight through (no version block, no
    // session to restore) to the sign-in screen.
    expect(find.text(t.signIn.title), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, 'a@b.c');
    await tester.tap(find.text(t.signIn.requestCodeButton));
    await tester.pumpAndSettle();

    // Moved to the code-entry step of the same screen.
    expect(find.text(t.signIn.verifyButton), findsOneWidget);

    await tester.enterText(
      find.byType(EditableText).first,
      FakeAuthService.fixedEmailCode,
    );
    await tester.tap(find.text(t.signIn.verifyButton));
    await tester.pumpAndSettle();

    // consentSheet is off by default and the onboarding stepper has
    // never been walked through for this fresh fake session, so sign-in
    // lands on Onboarding's first step (Profile) — never a carousel,
    // never straight to Home.
    expect(find.text(t.onboarding.stepProfileTitle), findsOneWidget);
    expect(find.text(t.onboarding.nextButton), findsOneWidget);
  });
}
