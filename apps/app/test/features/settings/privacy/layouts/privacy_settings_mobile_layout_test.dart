// Small builder helpers here return widgets on purpose: they only pre-fill
// a layout's callbacks for the tests below.
// ignore_for_file: solid_lints/avoid_returning_widgets

import 'package:app/features/settings/privacy/export_phase.dart';
import 'package:app/features/settings/privacy/layouts/privacy_settings_mobile_layout.dart';
import 'package:app/features/settings/privacy/privacy_settings_model.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/layout_harness.dart';

Widget _layout(
  PrivacySettingsModel model,
  TextEditingController stepUp, {
  ValueChanged<bool>? onSetConsent,
  VoidCallback? onStartExport,
}) => PrivacySettingsMobileLayout(
  model: model,
  stepUpCodeController: stepUp,
  onBack: noop,
  onSetConsent: onSetConsent ?? noop,
  onStartExport: onStartExport ?? noop,
  onVerifyStepUpAndExport: noop,
  onCopyExportedJson: noop,
);

void main() {
  testWidgets('PrivacySettingsMobileLayout forwards consent and export '
      'taps', (tester) async {
    final stepUp = TextEditingController();
    addTearDown(stepUp.dispose);
    bool? consent;
    var started = false;
    await pumpLayout(
      tester,
      _layout(
        const PrivacySettingsModel(),
        stepUp,
        onSetConsent: (accepted) => consent = accepted,
        onStartExport: () => started = true,
      ),
      width: mobileWidth,
    );

    await tester.tap(find.text(t.settings.privacy.changeConsentAccept));
    expect(consent, isTrue);
    await tester.tap(find.text(t.settings.privacy.exportButton));
    expect(started, isTrue);
  });

  testWidgets('PrivacySettingsMobileLayout shows the step-up field in the '
      'stepUp phase', (tester) async {
    final stepUp = TextEditingController();
    addTearDown(stepUp.dispose);
    await pumpLayout(
      tester,
      _layout(
        const PrivacySettingsModel(exportPhase: ExportPhase.stepUp),
        stepUp,
      ),
      width: mobileWidth,
    );

    expect(find.text(t.settings.privacy.exportStepUpTitle), findsOneWidget);
  });
}
