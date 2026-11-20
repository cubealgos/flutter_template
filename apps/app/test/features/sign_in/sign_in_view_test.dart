import 'package:app/app/di.dart';
import 'package:app/features/sign_in/layouts/sign_in_desktop_layout.dart';
import 'package:app/features/sign_in/layouts/sign_in_mobile_layout.dart';
import 'package:app/features/sign_in/sign_in_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/layout_harness.dart';
import '../../support/screen_harness.dart';

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  for (final brightness in Brightness.values) {
    testWidgets('renders in ${brightness.name} without throwing', (
      tester,
    ) async {
      await pumpScreen(tester, SignInView(), brightness: brightness);
      await tester.pumpAndSettle();

      expect(find.byType(SignInView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (width, isDesktop) in [
    (mobileWidth, false),
    (desktopWidth, true),
  ]) {
    testWidgets('shows the ${isDesktop ? 'desktop' : 'mobile'} layout at a '
        '${width.toInt()}px viewport', (tester) async {
      await pumpScreen(
        tester,
        SignInView(),
        brightness: Brightness.light,
        width: width,
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(SignInDesktopLayout),
        isDesktop ? findsOne : findsNothing,
      );
      expect(
        find.byType(SignInMobileLayout),
        isDesktop ? findsNothing : findsOne,
      );
    });
  }
}
