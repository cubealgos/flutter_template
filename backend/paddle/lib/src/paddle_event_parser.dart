import 'dart:convert';

import 'package:billing/billing.dart';
import 'package:crypto/crypto.dart';
import 'package:paddle_billing/src/paddle_parse_exception.dart';
import 'package:paddle_billing/src/paddle_plans.dart';
import 'package:paddle_billing/src/paddle_subscription_mapper.dart';

/// Turns a verified Paddle webhook body into a `ProviderEvent`.
///
/// The envelope is Paddle's (`event_id`, `event_type`, `occurred_at`,
/// `notification_id`, `data`:
/// <https://developer.paddle.com/webhooks/overview>). The `subscription.*`
/// events carry the whole subscription entity (`created`, `activated`,
/// `updated`, `trialing`, `past_due`, `paused`, `resumed`, `canceled`,
/// `imported`:
/// <https://developer.paddle.com/webhooks/subscriptions/subscription-updated>),
/// so each is read the same way: **two changes**, the state and the scheduled
/// change (which may be none), recorded as `<event id>#1` and `#2`. Every
/// other event type (a transaction, a customer, an adjustment) is a single
/// `recorded` row: kept for the audit trail, with no effect on an entitlement.
/// A subscription event whose custom data names no owner is `recorded` too,
/// with that reason.
class PaddleEventParser {
  /// Creates a parser naming plans through [plans].
  PaddleEventParser(PaddlePlans plans)
    : _mapper = PaddleSubscriptionMapper(plans);

  final PaddleSubscriptionMapper _mapper;

  /// Parses [rawBody], the exact bytes Paddle sent.
  ProviderEvent parse(List<int> rawBody) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(rawBody));
    } on FormatException {
      throw const PaddleParseException('the body is not JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const PaddleParseException('the body is not a JSON object');
    }
    final id = decoded['event_id'];
    final type = decoded['event_type'];
    final at = decoded['occurred_at'];
    final occurredAt = at is String ? DateTime.tryParse(at)?.toUtc() : null;
    if (id is! String || type is! String || occurredAt == null) {
      throw const PaddleParseException(
        'event_id, event_type and occurred_at are required',
      );
    }
    final data = decoded['data'];

    return ProviderEvent(
      id: id,
      type: type,
      occurredAt: occurredAt,
      bodyHash: sha256.convert(rawBody).toString(),
      changes: _changes(
        type,
        data is Map<String, dynamic> ? data : null,
        occurredAt,
      ),
    );
  }

  List<LedgerChange> _changes(
    String type,
    Map<String, dynamic>? data,
    DateTime occurredAt,
  ) {
    if (data == null) return _recorded(null, 'no data: $type');
    if (!type.startsWith('subscription.')) {
      return _recorded(data['subscription_id'], 'no entitlement effect: $type');
    }
    final state = _mapper.stateOf(data, eventAt: occurredAt);
    if (state == null) {
      return _recorded(data['id'], 'no owner in custom_data: $type');
    }

    return <LedgerChange>[
      LedgerChange.subscription(state),
      LedgerChange.scheduledChange(
        subscriptionId: state.subscriptionId,
        change: _mapper.scheduledChangeOf(data),
      ),
    ];
  }

  List<LedgerChange> _recorded(Object? subscriptionId, String detail) =>
      <LedgerChange>[
        LedgerChange.recorded(
          subscriptionId: subscriptionId is String ? subscriptionId : null,
          detail: detail,
        ),
      ];
}
