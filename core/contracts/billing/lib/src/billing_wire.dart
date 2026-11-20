import 'package:billing/src/billing_error.dart';
import 'package:billing/src/billing_owner.dart';
import 'package:billing/src/checkout_session.dart';
import 'package:billing/src/entitlement.dart';
import 'package:billing/src/entitlement_status.dart';
import 'package:billing/src/portal_session.dart';

/// The JSON the `billing` action speaks. `BillingOwner` travels as its key
/// (`user:<id>`, `team:<id>`).
abstract final class BillingWire {
  /// [entitlement] as JSON.
  static Map<String, dynamic> entitlementToJson(Entitlement entitlement) =>
      <String, dynamic>{
        'owner': entitlement.owner.key,
        'plan': entitlement.plan,
        'quantity': entitlement.quantity,
        'status': entitlement.status.name,
        'hasAccess': entitlement.hasAccess,
        'renewsAt': entitlement.renewsAt?.toUtc().toIso8601String(),
        'cancelsAt': entitlement.cancelsAt?.toUtc().toIso8601String(),
        'graceEndsAt': entitlement.graceEndsAt?.toUtc().toIso8601String(),
      };

  /// The entitlement in [json].
  static Entitlement entitlementFromJson(Map<String, dynamic> json) {
    final owner = BillingOwner.tryParse(json['owner']);
    if (owner == null) throw const FormatException('entitlement owner');
    DateTime? time(String key) {
      final value = json[key];

      return value is String ? DateTime.tryParse(value)?.toUtc() : null;
    }

    return Entitlement(
      owner: owner,
      plan: json['plan'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      status: EntitlementStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EntitlementStatus.none,
      ),
      hasAccess: json['hasAccess'] == true,
      renewsAt: time('renewsAt'),
      cancelsAt: time('cancelsAt'),
      graceEndsAt: time('graceEndsAt'),
    );
  }

  /// [session] as JSON.
  static Map<String, dynamic> checkoutToJson(CheckoutSession session) =>
      <String, dynamic>{
        'url': session.url.toString(),
        'transactionId': session.transactionId,
      };

  /// The checkout session in [json].
  static CheckoutSession checkoutFromJson(Map<String, dynamic> json) =>
      CheckoutSession(
        url: Uri.parse(json['url'] as String),
        transactionId: json['transactionId'] as String,
      );

  /// [session] as JSON.
  static Map<String, dynamic> portalToJson(PortalSession session) =>
      <String, dynamic>{'url': session.url.toString()};

  /// The portal session in [json].
  static PortalSession portalFromJson(Map<String, dynamic> json) =>
      PortalSession(url: Uri.parse(json['url'] as String));

  /// The body a failed call answers with.
  static Map<String, dynamic> errorToJson(
    BillingError error,
  ) => <String, dynamic>{
    'error': <String, dynamic>{'code': error.code, 'message': error.message},
  };

  /// The error an HTTP [statusCode] and body [json] stand for.
  static BillingError errorFromJson(int statusCode, Object? json) {
    final error = json is Map ? json['error'] : null;
    final fields = error is Map ? error : const <Object?, Object?>{};
    final text = fields['message'];
    final message = text is String ? text : 'Billing failed ($statusCode).';

    return switch (fields['code']) {
      'forbidden' => BillingForbiddenError(message),
      'no_subscription' => const BillingNoSubscriptionError(),
      'not_configured' => const BillingNotConfiguredError(),
      'invalid_request' || 'unknown_plan' => BillingInvalidError(message),
      _ => BillingProviderError(message),
    };
  }
}
