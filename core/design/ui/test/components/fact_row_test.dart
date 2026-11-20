import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/fact_row.dart';

import '../support/app_harness.dart';

void main() {
  group('AppFactRow', () {
    testWidgets('renders the label upper-cased and the value as-is', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(const AppFactRow(label: 'VAT ID', value: 'DE000000000')),
      );

      expect(find.text('VAT ID'), findsOneWidget);
      expect(find.text('DE000000000'), findsOneWidget);
    });

    testWidgets('lower-case labels are still rendered upper-cased', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(const AppFactRow(label: 'Company', value: 'Example GmbH')),
      );

      expect(find.text('COMPANY'), findsOneWidget);
      expect(find.text('Company'), findsNothing);
    });

    testWidgets('isFirst defaults to false', (tester) async {
      await tester.pumpWidget(
        testApp(const AppFactRow(label: 'Label', value: 'Value')),
      );

      final widget = tester.widget<AppFactRow>(find.byType(AppFactRow));
      expect(widget.isFirst, isFalse);
    });
  });
}
