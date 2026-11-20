import 'package:app/i18n/strings.g.dart';
import 'package:billing/billing.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The length of `YYYY-MM-DD`.
const int _dateLength = 10;

/// What the owner has now: the status in words, and the dates that matter
/// (renewal, a scheduled cancellation, the end of the grace period).
class EntitlementSummary extends StatelessWidget {
  /// Creates the summary.
  const EntitlementSummary({required this.entitlement, super.key});

  static String _status(EntitlementStatus status) {
    final p = t.settings.paywall;

    return switch (status) {
      EntitlementStatus.none => p.statusNone,
      EntitlementStatus.active => p.statusActive,
      EntitlementStatus.trialing => p.statusTrialing,
      EntitlementStatus.pastDue => p.statusPastDue,
      EntitlementStatus.expired => p.statusExpired,
      EntitlementStatus.paused => p.statusPaused,
      EntitlementStatus.canceled => p.statusCanceled,
    };
  }

  static String _date(DateTime value) =>
      value.toLocal().toIso8601String().substring(0, _dateLength);

  /// The entitlement the server computed.
  final Entitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final p = t.settings.paywall;
    final renews = entitlement.renewsAt;
    final cancels = entitlement.cancelsAt;
    final graceEnds = entitlement.graceEndsAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StyledText(_status(entitlement.status), style: h2Style()),
        if (entitlement.quantity > 0)
          StyledText(
            p.quantityValue(count: entitlement.quantity),
            style: bodyStyle(),
          ),
        if (renews != null)
          StyledText(
            p.renewsOn(date: _date(renews)),
            style: bodySmStyle().color(colorFgSubtle()),
          ),
        if (cancels != null)
          StyledText(
            p.cancelsOn(date: _date(cancels)),
            style: bodySmStyle().color(colorFgSubtle()),
          ),
        if (graceEnds != null && entitlement.hasAccess)
          StyledText(
            p.graceEndsOn(date: _date(graceEnds)),
            style: bodySmStyle().color(colorDanger()),
          ),
      ],
    );
  }
}
