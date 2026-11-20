import 'package:app/app/di.dart';
import 'package:app/features/legal/document/legal_document_type.dart';
import 'package:app/features/legal/document/legal_document_view.dart';
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
      await pumpScreen(
        tester,
        LegalDocumentView(type: LegalDocumentType.impressum),
        brightness: brightness,
      );
      await tester.pumpAndSettle();

      expect(find.byType(LegalDocumentView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
