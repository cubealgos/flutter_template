import 'package:app/app/config.dart';
import 'package:app/features/legal/document/layouts/legal_document_mobile_layout.dart';
import 'package:app/features/legal/document/legal_document_type.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/layout_harness.dart';

void main() {
  testWidgets('LegalDocumentMobileLayout renders the document title, notice '
      'and its facts', (tester) async {
    const config = AppConfig();
    await pumpLayout(
      tester,
      const LegalDocumentMobileLayout(
        type: LegalDocumentType.impressum,
        config: config,
        onBack: noop,
      ),
      width: mobileWidth,
    );

    expect(find.text(t.legal.impressum), findsOneWidget);
    expect(find.text(t.legal.document.templateNotice), findsOneWidget);
    expect(find.text(config.legalCompanyName), findsOneWidget);
  });
}
