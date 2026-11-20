import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The consent sheet's own content: eyebrow, title and message, the Accept
/// and Reject buttons side by side, and the link to Settings → Privacy.
class ConsentCard extends StatelessWidget {
  /// Creates the card.
  const ConsentCard({
    required this.onReject,
    required this.onAccept,
    required this.onOpenSettings,
    super.key,
  });

  /// Called when the user rejects.
  final VoidCallback onReject;

  /// Called when the user accepts.
  final VoidCallback onAccept;

  /// Called when the user opens Settings → Privacy.
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Box(
      style: BoxStyler().paddingAll(space6()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          StyledText(
            t.consent.eyebrowLabel.toUpperCase(),
            style: eyebrowStyle().color(colorLink()),
          ),
          const AppGap.v3(),
          StyledText(t.consent.title, style: h1Style()),
          const AppGap.v3(),
          StyledText(t.consent.message, style: bodyStyle()),
          const AppGap.v6(),
          // Deliberately the same variant, same size, side by side —
          // "equal-weight buttons on one layer" is a layout requirement,
          // not just a copy one; see `ConsentView`'s dartdoc.
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  semanticLabel: t.consent.reject,
                  onPressed: onReject,
                  variant: AppButtonVariant.secondary,
                  child: Text(t.consent.reject),
                ),
              ),
              const AppGap.h4(),
              Expanded(
                child: AppButton(
                  semanticLabel: t.consent.accept,
                  onPressed: onAccept,
                  variant: AppButtonVariant.secondary,
                  child: Text(t.consent.accept),
                ),
              ),
            ],
          ),
          const AppGap.v4(),
          Center(
            child: AppTextLinkButton(
              label: t.consent.settingsLink,
              onPressed: onOpenSettings,
            ),
          ),
        ],
      ),
    );
  }
}
