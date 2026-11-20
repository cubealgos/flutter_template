import 'package:app/features/consent/layouts/consent_mobile_layout.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/layout_harness.dart';

void main() {
  testWidgets('ConsentMobileLayout shows both choices and forwards their '
      'taps', (tester) async {
    var accepted = false;
    var rejected = false;
    await pumpLayout(
      tester,
      ConsentMobileLayout(
        onReject: () => rejected = true,
        onAccept: () => accepted = true,
        onOpenSettings: noop,
      ),
      width: mobileWidth,
    );

    await tester.tap(find.text(t.consent.accept));
    await tester.tap(find.text(t.consent.reject));

    expect(accepted, isTrue);
    expect(rejected, isTrue);
  });
}
