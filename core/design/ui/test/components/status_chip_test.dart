import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/status_chip.dart';

import '../support/app_harness.dart';

void main() {
  group('AppStatusChip', () {
    testWidgets('renders its label upper-cased regardless of input casing', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(const AppStatusChip(label: 'Accepted')));

      expect(find.text('ACCEPTED'), findsOneWidget);
      expect(find.text('Accepted'), findsNothing);
    });

    for (final tone in AppStatusTone.values) {
      testWidgets('the ${tone.name} tone renders without throwing', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(AppStatusChip(label: 'Status', tone: tone)),
        );

        expect(find.byType(AppStatusChip), findsOneWidget);
      });
    }

    testWidgets('defaults to the neutral tone', (tester) async {
      await tester.pumpWidget(testApp(const AppStatusChip(label: 'Not set')));

      final widget = tester.widget<AppStatusChip>(find.byType(AppStatusChip));
      expect(widget.tone, AppStatusTone.neutral);
    });
  });
}
