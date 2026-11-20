// Small builder helpers here return widgets on purpose: they only pre-fill
// a layout's callbacks for the tests below.
// ignore_for_file: solid_lints/avoid_returning_widgets

import 'package:app/features/settings/layouts/settings_hub_mobile_layout.dart';
import 'package:app/features/settings/settings_hub_model.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/layout_harness.dart';

Widget _layout({required bool showPaywall, VoidCallback? onPrivacy}) =>
    SettingsHubMobileLayout(
      model: SettingsHubModel(showPaywall: showPaywall),
      onBack: noop,
      onOpenLegal: noop,
      onOpenPrivacy: onPrivacy ?? noop,
      onOpenAccount: noop,
      onOpenTeams: noop,
      onOpenPaywall: noop,
    );

void main() {
  testWidgets('SettingsHubMobileLayout shows the paywall row only when '
      'enabled', (tester) async {
    await pumpLayout(tester, _layout(showPaywall: true), width: mobileWidth);
    expect(find.text(t.settings.paywallLink), findsOneWidget);

    await pumpLayout(tester, _layout(showPaywall: false), width: mobileWidth);
    expect(find.text(t.settings.paywallLink), findsNothing);
  });

  testWidgets('SettingsHubMobileLayout forwards row taps', (tester) async {
    var privacy = false;
    await pumpLayout(
      tester,
      _layout(showPaywall: false, onPrivacy: () => privacy = true),
      width: mobileWidth,
    );

    await tester.tap(find.text(t.settings.privacyLink));
    expect(privacy, isTrue);
  });
}
