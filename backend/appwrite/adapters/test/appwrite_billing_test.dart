// Test literals (status codes) are plain in a test and read worse as named
// constants.
// ignore_for_file: solid_lints/no_magic_number

import 'dart:convert';

import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:billing/billing.dart';
import 'package:test/test.dart';

import 'fakes/appwrite_model_fixtures.dart';

const BillingOwner _team = BillingOwner.team('t1');

void main() {
  final sent = <Map<String, dynamic>>[];

  AppwriteBilling billing(int status) {
    sent.clear();

    return AppwriteBilling.withApi(
      ApiClient.withExecutor(({
        required functionId,
        required body,
        required headers,
      }) async {
        sent.add(jsonDecode(body) as Map<String, dynamic>);

        return fakeExecution(status: status, body: jsonEncode(_answer));
      }),
    );
  }

  test(
    'every method is one call of the billing action with the owner key',
    () async {
      _answer = <String, dynamic>{
        'url': 'https://pay.example.test/x',
        'transactionId': 'txn_1',
      };
      final session = await billing(200)
          .startCheckout(plan: 'pro', quantity: 3, owner: _team);

      expect(session.transactionId, 'txn_1');
      expect(sent.single, <String, dynamic>{
        'action': 'billing',
        'op': 'start_checkout',
        'plan': 'pro',
        'quantity': 3,
        'owner': 'team:t1',
      });

      _answer = <String, dynamic>{'url': 'https://portal.example.test'};
      expect(
        (await billing(200).openPortal(_team)).url.host,
        'portal.example.test',
      );
      expect(sent.single['op'], 'open_portal');
    },
  );

  test(
    'an entitlement and a quantity update come back as Entitlement',
    () async {
      _answer = BillingWire.entitlementToJson(
        const Entitlement(
          owner: _team,
          plan: 'pro',
          quantity: 5,
          status: EntitlementStatus.active,
          hasAccess: true,
        ),
      );

      final entitlement = await billing(200).entitlement(_team);
      final updated = await billing(200)
          .updateQuantity(owner: _team, quantity: 5);

      expect(entitlement.hasAccess, isTrue);
      expect(entitlement.quantity, 5);
      expect(updated.quantity, 5);
      expect(sent.single['op'], 'update_quantity');
    },
  );

  test('a failed call becomes the BillingError of its code', () async {
    _answer = BillingWire.errorToJson(const BillingForbiddenError('no'));

    await expectLater(
      billing(403).openPortal(_team),
      throwsA(isA<BillingForbiddenError>()),
    );

    _answer = BillingWire.errorToJson(const BillingNoSubscriptionError());
    await expectLater(
      billing(404).entitlement(_team),
      throwsA(isA<BillingNoSubscriptionError>()),
    );
  });
}

// The body the fake execution answers, set per test.
Map<String, dynamic> _answer = <String, dynamic>{};
