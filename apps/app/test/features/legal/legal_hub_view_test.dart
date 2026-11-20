import 'package:app/app/di.dart';
import 'package:app/features/legal/legal_hub_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_harness.dart';

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  for (final brightness in Brightness.values) {
    testWidgets('renders in ${brightness.name} without throwing', (
      tester,
    ) async {
      await pumpScreen(tester, LegalHubView(), brightness: brightness);
      await tester.pumpAndSettle();

      expect(find.byType(LegalHubView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
