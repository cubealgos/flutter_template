import 'package:billing/billing.dart';
import 'package:paddle_billing/src/paddle_api.dart';
import 'package:paddle_billing/src/paddle_plans.dart';
import 'package:paddle_billing/src/paddle_subscription_mapper.dart';

/// Paddle's view of its subscriptions, for `BillingReconciler`. A state is
/// read from the entity as a **correction** (its scheduled change included),
/// dated by the entity's `updated_at` (else now), so a webhook that is older
/// than what the provider says now cannot revert it.
class PaddleProviderSubscriptions implements ProviderSubscriptions {
  /// Creates the view over [paddle].
  PaddleProviderSubscriptions({
    required PaddleApi paddle,
    required PaddlePlans plans,
    DateTime Function()? clock,
  }) : _api = paddle,
       _mapper = PaddleSubscriptionMapper(plans),
       _clock = clock ?? (() => DateTime.now().toUtc());

  final PaddleApi _api;
  final PaddleSubscriptionMapper _mapper;
  final DateTime Function() _clock;

  @override
  Future<SubscriptionState?> fetch(
    String subscriptionId, {
    BillingOwner? knownOwner,
  }) async {
    final entity = await _api.getSubscription(subscriptionId);

    return entity == null ? null : _state(entity, knownOwner);
  }

  @override
  Future<List<SubscriptionState>> list() async {
    final states = <SubscriptionState>[];
    for (final entity in await _api.listSubscriptions()) {
      final state = _state(entity, null);
      if (state != null) states.add(state);
    }

    return states;
  }

  SubscriptionState? _state(
    Map<String, dynamic> entity,
    BillingOwner? knownOwner,
  ) {
    final updated = entity['updated_at'];

    return _mapper.stateOf(
      entity,
      eventAt:
          (updated is String ? DateTime.tryParse(updated)?.toUtc() : null) ??
          _clock(),
      fallbackOwner: knownOwner,
      withScheduledChange: true,
    );
  }
}
