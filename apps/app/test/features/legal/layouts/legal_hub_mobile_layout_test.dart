// Small builder helpers here return widgets on purpose: they only pre-fill
// a layout's callbacks for the tests below.
// ignore_for_file: solid_lints/avoid_returning_widgets

import 'package:app/features/legal/layouts/legal_hub_mobile_layout.dart';
import 'package:app/features/legal/legal_hub_model.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/layout_harness.dart';

Widget _layout({required bool showAccessibility, VoidCallback? onLicences}) =>
    LegalHubMobileLayout(
      model: LegalHubModel(showAccessibilityStatement: showAccessibility),
      onBack: noop,
      onOpenImpressum: noop,
      onOpenDatenschutz: noop,
      onOpenAgb: noop,
      onOpenBarrierefreiheit: noop,
      onOpenLicences: onLicences ?? noop,
    );

void main() {
  testWidgets('LegalHubMobileLayout lists the documents, with the '
      'accessibility statement when enabled', (tester) async {
    await pumpLayout(
      tester,
      _layout(showAccessibility: true),
      width: mobileWidth,
    );

    expect(find.text(t.legal.impressum), findsOneWidget);
    expect(find.text(t.legal.barrierefreiheit), findsOneWidget);
  });

  testWidgets('LegalHubMobileLayout hides the accessibility statement when '
      'disabled and forwards taps', (tester) async {
    var licences = false;
    await pumpLayout(
      tester,
      _layout(showAccessibility: false, onLicences: () => licences = true),
      width: mobileWidth,
    );

    expect(find.text(t.legal.barrierefreiheit), findsNothing);
    await tester.tap(find.text(t.legal.licencesLink));
    expect(licences, isTrue);
  });
}
