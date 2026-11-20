import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/button.dart';
import 'package:ui/src/components/dialog.dart';

import '../support/app_harness.dart';

// A test-only composition helper, not a reusable package widget — kept as
// a function so call sites read as `testApp(_hostWithOpenButton())`.
// ignore: solid_lints/avoid_returning_widgets
/// A tiny host: a button that opens an [AppDialog] via [showAppDialog] when
/// pressed, with the given [barrier] configuration.
Widget _hostWithOpenButton({
  AppDialogBarrier barrier = const AppDialogBarrier(),
}) {
  return Builder(
    builder: (context) => AppButton(
      semanticLabel: 'Open',
      onPressed: () => showAppDialog<void>(
        context: context,
        semanticLabel: 'Confirm delete',
        barrier: barrier,
        builder: (_) => const Text('Are you sure?'),
      ),
      child: const Text('Open'),
    ),
  );
}

void main() {
  group('AppDialog / showAppDialog', () {
    testWidgets('opens with the caller-provided content', (tester) async {
      await tester.pumpWidget(testApp(_hostWithOpenButton()));
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.byType(AppDialog), findsOneWidget);
    });

    testWidgets(
      'the built-in close control has an accessible name and dismisses it',
      (tester) async {
        await tester.pumpWidget(testApp(_hostWithOpenButton()));
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        final handle = tester.ensureSemantics();
        expect(
          tester.getSemantics(find.bySemanticsLabel(RegExp('Close'))),
          isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
        );
        handle.dispose();

        await tester.tap(find.text('×'));
        await tester.pumpAndSettle();

        expect(find.byType(AppDialog), findsNothing);
      },
    );
  });

  group('AppDialog barrier dismissal', () {
    testWidgets('tapping the barrier dismisses a dismissible dialog', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(_hostWithOpenButton()));
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AppDialog), findsNothing);
    });

    testWidgets(
      'a non-dismissible barrier keeps the dialog open on outside tap',
      (tester) async {
        await tester.pumpWidget(
          testApp(
            _hostWithOpenButton(
              barrier: const AppDialogBarrier(dismissible: false),
            ),
          ),
        );
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.byType(AppDialog), findsOneWidget);
      },
    );
  });
}
