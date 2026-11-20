import 'package:app/features/bootstrap/bootstrap_model.dart';
import 'package:app/features/bootstrap/bootstrap_status.dart';
import 'package:app/features/bootstrap/layouts/bootstrap_mobile_layout.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/layout_harness.dart';

void main() {
  testWidgets('BootstrapMobileLayout shows the checking message', (
    tester,
  ) async {
    await pumpLayout(
      tester,
      const BootstrapMobileLayout(
        model: BootstrapModel(),
        onOpenUpdateLink: noop,
      ),
      width: mobileWidth,
    );

    expect(find.text(t.bootstrap.checkingVersion), findsOneWidget);
  });

  testWidgets('BootstrapMobileLayout shows the blocked notice and forwards '
      'the update tap', (tester) async {
    var opened = false;
    await pumpLayout(
      tester,
      BootstrapMobileLayout(
        model: BootstrapModel(
          status: BootstrapStatus.blocked,
          updateUrl: Uri.parse('https://example.com/update'),
        ),
        onOpenUpdateLink: () => opened = true,
      ),
      width: mobileWidth,
    );

    expect(find.text(t.bootstrap.blockedTitle), findsOneWidget);
    await tester.tap(find.text(t.bootstrap.updateButton));
    expect(opened, isTrue);
  });
}
