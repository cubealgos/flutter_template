import 'package:app/features/sign_in/layouts/sign_in_desktop_layout.dart';
import 'package:app/features/sign_in/layouts/sign_in_mobile_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/layout_harness.dart';

const _form = SizedBox(key: Key('form'), height: 100, child: Text('form'));

void main() {
  testWidgets('SignInMobileLayout top-anchors the form at the mobile '
      'breakpoint', (tester) async {
    await pumpLayout(
      tester,
      const SignInMobileLayout(form: _form),
      width: mobileWidth,
    );

    expect(find.byKey(const Key('form')), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(const Key('form'))).dy,
      lessThan(topBand),
    );
  });

  testWidgets('SignInDesktopLayout centers the form vertically at the '
      'desktop breakpoint', (tester) async {
    await pumpLayout(
      tester,
      const SignInDesktopLayout(form: _form),
      width: desktopWidth,
    );

    expect(find.byKey(const Key('form')), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(const Key('form'))).dy,
      closeTo(middle, 1),
    );
  });
}
