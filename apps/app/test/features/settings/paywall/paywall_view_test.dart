import 'package:app/app/di.dart';
import 'package:app/features/settings/paywall/paywall_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/screen_harness.dart';

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  for (final brightness in Brightness.values) {
    testWidgets('renders in ${brightness.name} without throwing', (
      tester,
    ) async {
      await pumpScreen(tester, PaywallView(), brightness: brightness);
      await tester.pumpAndSettle();

      expect(find.byType(PaywallView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
