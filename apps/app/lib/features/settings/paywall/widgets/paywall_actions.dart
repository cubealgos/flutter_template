import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The buttons that fit the subscription state: *Subscribe* with none, else
/// *Change units (prorated)* and *Manage billing*; *refresh* always.
class PaywallActions extends StatelessWidget {
  /// Creates the buttons.
  const PaywallActions({
    required this.subscribed,
    required this.busy,
    required this.onSubscribe,
    required this.onApplyQuantity,
    required this.onManage,
    required this.onRefresh,
    super.key,
  });

  /// Whether the owner has access now.
  final bool subscribed;

  /// Whether a call is running (shows a spinner on the main button).
  final bool busy;

  /// Called when "Subscribe" is pressed.
  final VoidCallback onSubscribe;

  /// Called when "Change units" is pressed.
  final VoidCallback onApplyQuantity;

  /// Called when "Manage billing" is pressed.
  final VoidCallback onManage;

  /// Called when "I have paid, refresh" is pressed.
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final p = t.settings.paywall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (subscribed) ...<Widget>[
          AppFullWidthButton(
            child: AppButton(
              semanticLabel: p.applyQuantityButton,
              loading: busy,
              onPressed: onApplyQuantity,
              child: Text(p.applyQuantityButton),
            ),
          ),
          const AppGap.v2(),
          AppFullWidthButton(
            child: AppButton(
              semanticLabel: p.manageButton,
              variant: AppButtonVariant.secondary,
              onPressed: onManage,
              child: Text(p.manageButton),
            ),
          ),
        ] else
          AppFullWidthButton(
            child: AppButton(
              semanticLabel: p.subscribeButton,
              loading: busy,
              onPressed: onSubscribe,
              child: Text(p.subscribeButton),
            ),
          ),
        const AppGap.v2(),
        AppFullWidthButton(
          child: AppButton(
            semanticLabel: p.refreshButton,
            variant: AppButtonVariant.secondary,
            onPressed: onRefresh,
            child: Text(p.refreshButton),
          ),
        ),
      ],
    );
  }
}
