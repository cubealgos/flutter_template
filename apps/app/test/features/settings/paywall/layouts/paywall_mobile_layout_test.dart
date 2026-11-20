// Test literals, `late` fixtures, `!` on a value the test just made and a
// do-nothing fake method are plain in a test.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name, solid_lints/no_empty_block, solid_lints/avoid_returning_widgets

import 'package:app/features/settings/paywall/layouts/paywall_mobile_layout.dart';
import 'package:app/features/settings/paywall/paywall_model.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:billing/billing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/layout_harness.dart';

const BillingOwner _owner = BillingOwner.team('t1');

Widget _layout(PaywallModel model) => PaywallMobileLayout(
  model: model,
  onBack: noop,
  onRefresh: noop,
  onIncrease: noop,
  onDecrease: noop,
  onSubscribe: noop,
  onApplyQuantity: noop,
  onManage: noop,
  onOpenAgb: noop,
  onOpenDatenschutz: noop,
);

void main() {
  final p = t.settings.paywall;

  testWidgets('no subscription: offers Subscribe, not Manage', (tester) async {
    await pumpLayout(
      tester,
      _layout(
        const PaywallModel(
          entitlement: Entitlement.none(_owner),
          loading: false,
        ),
      ),
      width: mobileWidth,
    );

    expect(find.text(p.statusNone), findsOneWidget);
    expect(find.text(p.subscribeButton), findsOneWidget);
    expect(find.text(p.manageButton), findsNothing);
  });

  testWidgets('subscribed: shows status, units and renewal, and offers '
      'Change units and Manage', (tester) async {
    await pumpLayout(
      tester,
      _layout(
        PaywallModel(
          entitlement: Entitlement(
            owner: _owner,
            plan: 'pro',
            quantity: 4,
            status: EntitlementStatus.active,
            hasAccess: true,
            renewsAt: DateTime.utc(2026, 11),
          ),
          loading: false,
          quantity: 4,
        ),
      ),
      width: mobileWidth,
    );

    expect(find.text(p.statusActive), findsOneWidget);
    expect(find.text(p.quantityValue(count: 4)), findsOneWidget);
    expect(find.text(p.renewsOn(date: '2026-11-01')), findsOneWidget);
    expect(find.text(p.applyQuantityButton), findsOneWidget);
    expect(find.text(p.manageButton), findsOneWidget);
    expect(find.text(p.subscribeButton), findsNothing);
  });

  testWidgets('past due inside the grace period warns with the date', (
    tester,
  ) async {
    await pumpLayout(
      tester,
      _layout(
        PaywallModel(
          entitlement: Entitlement(
            owner: _owner,
            plan: 'pro',
            quantity: 2,
            status: EntitlementStatus.pastDue,
            hasAccess: true,
            graceEndsAt: DateTime.utc(2026, 10, 8),
          ),
          loading: false,
        ),
      ),
      width: mobileWidth,
    );

    expect(find.text(p.statusPastDue), findsOneWidget);
    expect(find.text(p.graceEndsOn(date: '2026-10-08')), findsOneWidget);
  });

  testWidgets('signed out and failed states', (tester) async {
    await pumpLayout(
      tester,
      _layout(const PaywallModel(signedOut: true, failed: true)),
      width: mobileWidth,
    );

    expect(find.text(p.signedOut), findsOneWidget);
    expect(find.text(p.failed), findsOneWidget);
    expect(find.text(p.subscribeButton), findsNothing);
  });
}
