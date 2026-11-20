import 'package:app/features/bootstrap/bootstrap_model.dart';
import 'package:app/features/bootstrap/bootstrap_status.dart';
import 'package:app/features/bootstrap/widgets/app_mark.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The bootstrap/splash screen: the checking mark, or the
/// blocked-version notice with its optional update button.
class BootstrapMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const BootstrapMobileLayout({
    required this.model,
    required this.onOpenUpdateLink,
    super.key,
  });

  /// The bootstrap state being rendered.
  final BootstrapModel model;

  /// Called when the update button is pressed.
  final VoidCallback onOpenUpdateLink;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppContentWrapper(
        width: AppContentWidth.auth,
        child: Box(
          style: BoxStyler().paddingAll(space6()),
          child: Center(
            child: switch (model.status) {
              BootstrapStatus.checking => Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const AppMark(),
                  const AppGap.v6(),
                  StyledText(t.bootstrap.checkingVersion, style: bodyStyle()),
                ],
              ),
              BootstrapStatus.blocked => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Center(child: AppMark()),
                  const AppGap.v6(),
                  StyledText(t.bootstrap.blockedTitle, style: h1Style()),
                  const AppGap.v2(),
                  StyledText(
                    model.updateMessage ?? t.bootstrap.blockedMessage,
                    style: bodyStyle(),
                  ),
                  if (model.updateUrl != null) ...<Widget>[
                    const AppGap.v4(),
                    AppFullWidthButton(
                      child: AppButton(
                        semanticLabel: t.bootstrap.updateButton,
                        onPressed: onOpenUpdateLink,
                        child: Text(t.bootstrap.updateButton),
                      ),
                    ),
                  ],
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}
