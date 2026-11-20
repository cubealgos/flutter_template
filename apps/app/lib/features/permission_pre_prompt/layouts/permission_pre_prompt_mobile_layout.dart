import 'package:app/features/permission_pre_prompt/permission_kind.dart';
import 'package:app/features/permission_pre_prompt/permission_pre_prompt_model.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The pre-permission dialog: title, explanation and the "Not now" /
/// "Continue" pair, built from `AppDialog` chrome. A dialog keeps the same
/// shape on every viewport, so there is no wider variant.
class PermissionPrePromptMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const PermissionPrePromptMobileLayout({
    required this.model,
    required this.onNotNow,
    required this.onContinue,
    super.key,
  });

  /// The prompt state being rendered.
  final PermissionPrePromptModel model;

  /// Called when "Not now" is pressed.
  final VoidCallback onNotNow;

  /// Called when "Continue" is pressed.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final (title, message) = switch (model.kind) {
      PermissionKind.push => (
        t.permissionPrePrompt.pushTitle,
        t.permissionPrePrompt.pushMessage,
      ),
      PermissionKind.att => (
        t.permissionPrePrompt.attTitle,
        t.permissionPrePrompt.attMessage,
      ),
      PermissionKind.location => (
        t.permissionPrePrompt.locationTitle,
        t.permissionPrePrompt.locationMessage,
      ),
    };

    return AppTheme(
      child: AppDialog(
        semanticLabel: title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StyledText(title, style: h3Style()),
            const AppGap.v2(),
            StyledText(message, style: bodyStyle()),
            const AppGap.v4(),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    semanticLabel: t.common.notNow,
                    onPressed: onNotNow,
                    variant: AppButtonVariant.secondary,
                    child: Text(t.common.notNow),
                  ),
                ),
                const AppGap.h3(),
                Expanded(
                  child: AppButton(
                    semanticLabel: t.common.continueLabel,
                    onPressed: onContinue,
                    child: Text(t.common.continueLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
