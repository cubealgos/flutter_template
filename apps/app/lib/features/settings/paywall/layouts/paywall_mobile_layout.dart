import 'package:app/features/settings/paywall/paywall_model.dart';
import 'package:app/features/settings/paywall/widgets/entitlement_summary.dart';
import 'package:app/features/settings/paywall/widgets/paywall_actions.dart';
import 'package:app/features/settings/paywall/widgets/quantity_stepper.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:app/shared/widgets/legal_links_row.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The subscription screen: what the owner has now, the quantity, and the
/// buttons that fit the state (subscribe, change quantity, manage billing).
class PaywallMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const PaywallMobileLayout({
    required this.model,
    required this.onBack,
    required this.onRefresh,
    required this.onIncrease,
    required this.onDecrease,
    required this.onSubscribe,
    required this.onApplyQuantity,
    required this.onManage,
    required this.onOpenAgb,
    required this.onOpenDatenschutz,
    super.key,
  });

  /// The state to render.
  final PaywallModel model;

  /// Called when the back chevron is pressed.
  final VoidCallback onBack;

  /// Called when "Refresh" is pressed.
  final VoidCallback onRefresh;

  /// Called when the quantity "+" is pressed.
  final VoidCallback onIncrease;

  /// Called when the quantity "-" is pressed.
  final VoidCallback onDecrease;

  /// Called when "Subscribe" is pressed.
  final VoidCallback onSubscribe;

  /// Called when "Apply" (change the quantity) is pressed.
  final VoidCallback onApplyQuantity;

  /// Called when "Manage billing" is pressed.
  final VoidCallback onManage;

  /// Called when the AGB link is pressed.
  final VoidCallback onOpenAgb;

  /// Called when the Datenschutz link is pressed.
  final VoidCallback onOpenDatenschutz;

  @override
  Widget build(BuildContext context) {
    final p = t.settings.paywall;
    final entitlement = model.entitlement;
    final subscribed = entitlement != null && entitlement.hasAccess;

    return AppScreenScaffold(
      title: p.title,
      back: AppScreenHeaderBack(
        semanticLabel: t.common.back,
        onPressed: onBack,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (model.failed)
            StyledText(p.failed, style: bodyStyle().color(colorDanger())),
          if (model.signedOut)
            StyledText(p.signedOut, style: bodyStyle())
          else if (model.loading)
            const Center(child: AppLoadingIndicator())
          else ...<Widget>[
            if (entitlement != null)
              EntitlementSummary(entitlement: entitlement),
            const AppGap.v4(),
            QuantityStepper(
              quantity: model.quantity,
              onIncrease: onIncrease,
              onDecrease: onDecrease,
            ),
            const AppGap.v4(),
            PaywallActions(
              subscribed: subscribed,
              busy: model.busy,
              onSubscribe: onSubscribe,
              onApplyQuantity: onApplyQuantity,
              onManage: onManage,
              onRefresh: onRefresh,
            ),
          ],
          const AppGap.v3(),
          LegalLinksRow(
            onOpenAgb: onOpenAgb,
            onOpenDatenschutz: onOpenDatenschutz,
          ),
        ],
      ),
    );
  }
}
