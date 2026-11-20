import 'package:billing/src/billing_owner.dart';
import 'package:billing/src/entitlement_status.dart';
import 'package:meta/meta.dart';

/// What an owner may use, **at one moment**: a function of the subscription's
/// state and the time it was computed (`SubscriptionState.entitlementAt`),
/// never a stored flag, so the end of a grace period or of a scheduled
/// cancellation needs no event to take effect.
@immutable
class Entitlement {
  /// Creates an entitlement.
  const Entitlement({
    required this.owner,
    required this.status,
    required this.hasAccess,
    this.plan,
    this.renewsAt,
    this.cancelsAt,
    this.graceEndsAt,
    this.quantity = 0,
  });

  /// The entitlement of an owner with no subscription.
  const Entitlement.none(this.owner)
    : status = EntitlementStatus.none,
      hasAccess = false,
      plan = null,
      quantity = 0,
      renewsAt = null,
      cancelsAt = null,
      graceEndsAt = null;

  /// Whose entitlement it is.
  final BillingOwner owner;

  /// The plan key, or null when there is no subscription.
  final String? plan;

  /// How many units are paid for (monitored sites, seats), 0 for none.
  final int quantity;

  /// What the entitlement is now.
  final EntitlementStatus status;

  /// Whether the owner may use the product now. Gate on this, never on
  /// [status] alone: a past-due subscription inside its grace period has
  /// access.
  final bool hasAccess;

  /// The next renewal, when one is due.
  final DateTime? renewsAt;

  /// When a scheduled cancellation takes effect, if one is pending.
  final DateTime? cancelsAt;

  /// When the grace period ends, for a past-due subscription.
  final DateTime? graceEndsAt;

  @override
  int get hashCode => Object.hash(
    owner,
    plan,
    quantity,
    status,
    hasAccess,
    renewsAt,
    cancelsAt,
    graceEndsAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Entitlement &&
      other.owner == owner &&
      other.plan == plan &&
      other.quantity == quantity &&
      other.status == status &&
      other.hasAccess == hasAccess &&
      other.renewsAt == renewsAt &&
      other.cancelsAt == cancelsAt &&
      other.graceEndsAt == graceEndsAt;
}
