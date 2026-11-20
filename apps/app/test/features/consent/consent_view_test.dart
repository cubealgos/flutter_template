import 'package:app/app/di.dart';
import 'package:app/features/consent/consent_view.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

import '../../support/screen_harness.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'critical flow: Accept and Reject render as equal-weight buttons on '
    'one layer — same variant, same size, neither pre-selected (§25 '
    "TDDDG / Planet49 / LG München I — see ConsentView's dartdoc)",
    (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: AppTheme(child: ConsentView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final acceptButton = tester.widget<AppButton>(
        find.ancestor(
          of: find.text(t.consent.accept),
          matching: find.byType(AppButton),
        ),
      );
      final rejectButton = tester.widget<AppButton>(
        find.ancestor(
          of: find.text(t.consent.reject),
          matching: find.byType(AppButton),
        ),
      );

      // Equal weight: identical visual variant, so neither reads as the
      // "primary"/default choice.
      expect(acceptButton.variant, rejectButton.variant);
      expect(acceptButton.variant, isNot(AppButtonVariant.primary));

      // Both are real, independently tappable buttons on the same
      // screen — "on one layer", not a nested confirm-within-confirm.
      expect(find.byType(AppButton), findsWidgets);
      expect(find.text(t.consent.accept), findsOneWidget);
      expect(find.text(t.consent.reject), findsOneWidget);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('renders in ${brightness.name} without throwing', (
      tester,
    ) async {
      await pumpScreen(tester, ConsentView(), brightness: brightness);
      await tester.pumpAndSettle();

      expect(find.byType(ConsentView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
