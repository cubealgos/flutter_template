// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'dart:convert';

import 'package:billing/billing.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:hooks/src/hook_request.dart';
import 'package:paddle_billing/paddle_billing.dart';

/// The webhook secret of the tests.
const String webhookSecret = 'pdl_ntfset_test_secret';

/// A fixed "now".
final DateTime now = DateTime.utc(2026, 10, 1, 12);

/// A subscription event body. Deliberately not what `jsonEncode` would
/// produce: spacing, a unicode escape and a trailing newline, which a
/// re-serialisation would change.
final List<int> eventBody = utf8.encode(
  '{ "event_id" : "evt_01", "event_type":"subscription.updated",\n'
  '  "occurred_at":"2026-10-01T12:00:00Z", "notification_id":"ntf_1",\n'
  '  "data":{"id":"sub_01","status":"active","customer_id":"ctm_01",\n'
  '    "items":[{"status":"active","quantity":3, '
  '"price":{"id":"pri_pro"}}],\n'
  '    "next_billed_at":"2026-11-01T12:00:00Z","scheduled_change":null,\n'
  '    "custom_data":{"owner":"team:t\\u0031"}}}\n',
);

/// The ledger and entitlement store a test engine runs on.
class Stores {
  /// The ledger.
  final InMemoryBillingLedger ledger = InMemoryBillingLedger();

  /// The entitlements.
  final InMemoryEntitlementStore entitlements = InMemoryEntitlementStore();

  /// An engine over them.
  BillingEngine engine() =>
      BillingEngine(ledger: ledger, entitlements: entitlements);
}

/// A request to `/paddle` with [body], signed under [secret] at [signedAt]
/// (or carrying [signature] verbatim).
HookRequest paddleRequest(
  List<int> body, {
  DateTime? signedAt,
  String? signature,
  Map<String, String>? environment,
  List<String>? logs,
  String secret = webhookSecret,
}) => HookRequest(
  method: 'POST',
  path: '/paddle',
  headers: <String, String>{
    'paddle-signature':
        signature ??
        PaddleSignature.sign(
          rawBody: body,
          secret: secret,
          timestamp: signedAt ?? now,
        ),
  },
  rawBody: body,
  environment:
      environment ??
      <String, String>{
        'PADDLE_WEBHOOK_SECRET': webhookSecret,
        'PADDLE_PLANS': '{"pro":"pri_pro"}',
      },
  client: Client(),
  log: logs?.add,
);
