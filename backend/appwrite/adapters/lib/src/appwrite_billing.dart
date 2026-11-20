import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/src/api_client.dart';
import 'package:billing/billing.dart';

/// The name of the router action this adapter calls.
const String billingAction = 'billing';

/// The [Billing] backed by the `billing` action of the `api` Function.
///
/// The app never talks to the payment provider and never reads the
/// entitlement tables (they are `serverOnly`): every method is one call to
/// the action, which acts as the signed-in caller and answers the entitlement
/// the server computed from the ledger and the clock. A failure arrives as a
/// `BillingError` with the action's stable code.
class AppwriteBilling implements Billing {
  /// Creates the adapter calling the Function through [client].
  AppwriteBilling(Client client) : _api = ApiClient(Functions(client));

  /// Creates the adapter over an `ApiClient`, for tests.
  AppwriteBilling.withApi(this._api);

  final ApiClient _api;

  @override
  Future<CheckoutSession> startCheckout({
    required String plan,
    required int quantity,
    required BillingOwner owner,
  }) async => BillingWire.checkoutFromJson(
    await _call('start_checkout', <String, dynamic>{
      'plan': plan,
      'quantity': quantity,
      'owner': owner.key,
    }),
  );

  @override
  Future<PortalSession> openPortal(BillingOwner owner) async =>
      BillingWire.portalFromJson(
        await _call('open_portal', <String, dynamic>{'owner': owner.key}),
      );

  @override
  Future<Entitlement> updateQuantity({
    required BillingOwner owner,
    required int quantity,
  }) async => BillingWire.entitlementFromJson(
    await _call('update_quantity', <String, dynamic>{
      'owner': owner.key,
      'quantity': quantity,
    }),
  );

  @override
  Future<Entitlement> entitlement(BillingOwner owner) async =>
      BillingWire.entitlementFromJson(
        await _call('entitlement', <String, dynamic>{'owner': owner.key}),
      );

  Future<Map<String, dynamic>> _call(
    String op,
    Map<String, dynamic> fields,
  ) async {
    try {
      final body = await _api.call(
        billingAction,
        fields: <String, dynamic>{...fields, 'op': op},
      );

      return jsonDecode(body) as Map<String, dynamic>;
    } on AppwriteException catch (e) {
      throw _errorOf(e);
    }
  }

  /// `ApiClient` carries a failed call as "`action` returned `status`:
  /// `body`"; the body is the action's `{"error": {...}}`.
  static BillingError _errorOf(AppwriteException e) {
    final message = e.message ?? '';
    final start = message.indexOf('{');
    Object? json;
    if (start >= 0) {
      try {
        json = jsonDecode(message.substring(start));
      } on FormatException {
        json = null;
      }
    }

    return BillingWire.errorFromJson(e.code ?? 0, json);
  }
}
