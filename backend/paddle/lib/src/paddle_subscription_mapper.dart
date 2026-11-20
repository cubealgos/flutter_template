import 'package:billing/billing.dart';
import 'package:paddle_billing/src/paddle_parse_exception.dart';
import 'package:paddle_billing/src/paddle_plans.dart';

/// The key of the owner in a transaction's (and so a subscription's)
/// `custom_data`: Paddle copies a transaction's custom data to the
/// subscription it creates
/// (<https://developer.paddle.com/build/transactions/custom-data>). The key's
/// name is this template's own.
const String ownerCustomDataKey = 'owner';

/// Maps Paddle's subscription entity to a `SubscriptionState`.
///
/// Field names are those of Paddle's subscription entity
/// (<https://developer.paddle.com/api-reference/subscriptions/get-subscription>):
/// `id`, `status`, `customer_id`, `items[].quantity`, `items[].price.id`,
/// `items[].status`, `current_billing_period.ends_at`, `next_billed_at`,
/// `canceled_at`, `scheduled_change.{action,effective_at}`, `custom_data`.
/// A subscription is taken to have **one recurring item**: the first active
/// (or trialing) one, else the first.
class PaddleSubscriptionMapper {
  /// Creates a mapper that names plans through [plans].
  const PaddleSubscriptionMapper(this.plans);

  /// The plan keys.
  final PaddlePlans plans;

  /// The owner [entity]'s custom data names, or null.
  BillingOwner? ownerOf(Map<String, dynamic> entity) {
    final custom = entity['custom_data'];

    return custom is Map
        ? BillingOwner.tryParse(custom[ownerCustomDataKey])
        : null;
  }

  /// The scheduled change [entity] carries, or null.
  ScheduledChange? scheduledChangeOf(Map<String, dynamic> entity) {
    final scheduled = entity['scheduled_change'];
    if (scheduled is! Map) return null;
    final action = ScheduledAction.fromName(scheduled['action']);
    final at = _time(scheduled['effective_at']);

    return action == null || at == null
        ? null
        : ScheduledChange(action: action, effectiveAt: at);
  }

  /// The state [entity] describes as of [eventAt], with [fallbackOwner] when
  /// the entity's custom data names none; null when there is no owner at all.
  /// [withScheduledChange] says whether the entity's scheduled change belongs
  /// in the state (a correction) or is carried by a change of its own (a
  /// webhook).
  SubscriptionState? stateOf(
    Map<String, dynamic> entity, {
    required DateTime eventAt,
    BillingOwner? fallbackOwner,
    bool withScheduledChange = false,
  }) {
    final owner = ownerOf(entity) ?? fallbackOwner;
    if (owner == null) return null;
    final id = entity['id'];
    final status = ProviderStatus.fromWire(entity['status']);
    if (id is! String || status == null) {
      throw const PaddleParseException('subscription without id or status');
    }
    final item = _recurringItem(entity['items']);

    return SubscriptionState(
      subscriptionId: id,
      customerId: entity['customer_id'] as String?,
      owner: owner,
      plan: plans.planFor(priceIdOf(entity) ?? 'unknown'),
      quantity: (item?['quantity'] as num?)?.toInt() ?? 0,
      status: status,
      currentPeriodEnd: _periodEnd(entity['current_billing_period']),
      nextBilledAt: _time(entity['next_billed_at']),
      canceledAt: _time(entity['canceled_at']),
      scheduledChange: withScheduledChange ? scheduledChangeOf(entity) : null,
      eventAt: eventAt,
    );
  }

  DateTime? _periodEnd(Object? period) =>
      period is Map ? _time(period['ends_at']) : null;

  /// The price ID of [entity]'s recurring item, or null.
  String? priceIdOf(Map<String, dynamic> entity) {
    final price = _recurringItem(entity['items'])?['price'];

    return price is Map ? price['id'] as String? : null;
  }

  Map<String, dynamic>? _recurringItem(Object? items) {
    if (items is! List) return null;
    final maps = items.whereType<Map<String, dynamic>>().toList();
    for (final item in maps) {
      if (item['status'] == 'active' || item['status'] == 'trialing') {
        return item;
      }
    }

    return maps.isEmpty ? null : maps.first;
  }

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
