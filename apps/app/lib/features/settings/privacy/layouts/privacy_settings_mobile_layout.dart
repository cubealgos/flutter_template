import 'package:app/features/settings/privacy/consent_status.dart';
import 'package:app/features/settings/privacy/export_phase.dart';
import 'package:app/features/settings/privacy/privacy_settings_model.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// Settings → Privacy: change consent (withdrawable at any time) and
/// export the user's own data with step-up re-verification.
class PrivacySettingsMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const PrivacySettingsMobileLayout({
    required this.model,
    required this.stepUpCodeController,
    required this.onBack,
    required this.onSetConsent,
    required this.onStartExport,
    required this.onVerifyStepUpAndExport,
    required this.onCopyExportedJson,
    super.key,
  });

  /// The privacy state being rendered.
  final PrivacySettingsModel model;

  /// The step-up code field's text controller.
  final TextEditingController stepUpCodeController;

  /// Called when the back chevron is pressed.
  final VoidCallback onBack;

  /// Called with `true`/`false` when the user accepts/rejects consent.
  final ValueChanged<bool> onSetConsent;

  /// Called when the export button is pressed.
  final VoidCallback onStartExport;

  /// Called with the entered step-up code when it is submitted.
  final ValueChanged<String> onVerifyStepUpAndExport;

  /// Called when the exported JSON's copy button is pressed.
  final VoidCallback onCopyExportedJson;

  (String, AppStatusTone) _consentChip(ConsentStatus status) =>
      switch (status) {
        ConsentStatus.accepted => (
          t.settings.privacy.consentChipAccepted,
          AppStatusTone.success,
        ),
        ConsentStatus.rejected => (
          t.settings.privacy.consentChipRejected,
          AppStatusTone.danger,
        ),
        ConsentStatus.notSet => (
          t.settings.privacy.consentChipNotSet,
          AppStatusTone.neutral,
        ),
      };

  List<Widget> _consentSection() {
    final (label, tone) = _consentChip(model.consentStatus);

    return <Widget>[
      StyledText(t.settings.privacy.consentSectionTitle, style: h2Style()),
      const AppGap.v3(),
      AppStatusChip(label: label, tone: tone),
      const AppGap.v3(),
      Row(
        children: <Widget>[
          Expanded(
            child: AppButton(
              semanticLabel: t.settings.privacy.changeConsentReject,
              onPressed: () => onSetConsent(false),
              variant: AppButtonVariant.secondary,
              child: Text(t.settings.privacy.changeConsentReject),
            ),
          ),
          const AppGap.h3(),
          Expanded(
            child: AppButton(
              semanticLabel: t.settings.privacy.changeConsentAccept,
              onPressed: () => onSetConsent(true),
              variant: AppButtonVariant.secondary,
              child: Text(t.settings.privacy.changeConsentAccept),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _exportSection() {
    return switch (model.exportPhase) {
      ExportPhase.idle => <Widget>[
        AppFullWidthButton(
          child: AppButton(
            semanticLabel: t.settings.privacy.exportButton,
            onPressed: onStartExport,
            child: Text(t.settings.privacy.exportButton),
          ),
        ),
      ],
      ExportPhase.stepUp || ExportPhase.exporting => <Widget>[
        StyledText(t.settings.privacy.exportStepUpTitle, style: h3Style()),
        const AppGap.v1(),
        StyledText(t.settings.privacy.exportStepUpMessage, style: bodyStyle()),
        const AppGap.v2(),
        AppCodeField(
          label: t.settings.privacy.exportCodeLabel,
          controller: stepUpCodeController,
          enabled: model.exportPhase != ExportPhase.exporting,
        ),
        const AppGap.v2(),
        AppFullWidthButton(
          child: AppButton(
            semanticLabel: t.settings.privacy.exportVerifyButton,
            loading: model.exportPhase == ExportPhase.exporting,
            onPressed: () => onVerifyStepUpAndExport(stepUpCodeController.text),
            child: Text(t.settings.privacy.exportVerifyButton),
          ),
        ),
      ],
      ExportPhase.result => <Widget>[
        StyledText(t.settings.privacy.exportResultTitle, style: h3Style()),
        const AppGap.v2(),
        AppCodeBlock(text: model.exportedJson ?? ''),
        const AppGap.v2(),
        AppButton(
          semanticLabel: t.settings.privacy.exportCopyButton,
          onPressed: onCopyExportedJson,
          variant: AppButtonVariant.secondary,
          child: Text(t.settings.privacy.exportCopyButton),
        ),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: t.settings.privacy.title,
      back: AppScreenHeaderBack(
        semanticLabel: t.common.back,
        onPressed: onBack,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ..._consentSection(),
          const AppGap.v8(),
          const AppDivider(),
          const AppGap.v8(),
          StyledText(t.settings.privacy.exportTitle, style: h2Style()),
          const AppGap.v1(),
          StyledText(t.settings.privacy.exportDescription, style: bodyStyle()),
          const AppGap.v3(),
          ..._exportSection(),
        ],
      ),
    );
  }
}
