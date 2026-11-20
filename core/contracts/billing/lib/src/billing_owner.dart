import 'package:billing/src/billing_owner_kind.dart';
import 'package:meta/meta.dart';

/// The user or team a subscription is billed to.
///
/// Team-first: an app with teams bills the active team; an app without them
/// bills the user. [key] is the one string form (`user:<id>`, `team:<id>`)
/// the ledger, the entitlement table and the provider's custom data carry.
@immutable
class BillingOwner {
  /// A user owner.
  const BillingOwner.user(this.id) : kind = BillingOwnerKind.user;

  /// A team owner.
  const BillingOwner.team(this.id) : kind = BillingOwnerKind.team;

  /// Whether the owner is a user or a team.
  final BillingOwnerKind kind;

  /// The user or team ID.
  final String id;

  /// `user:<id>` or `team:<id>`.
  String get key => '${kind.name}:$id';

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  bool operator ==(Object other) =>
      other is BillingOwner && other.kind == kind && other.id == id;

  @override
  String toString() => key;

  /// The owner [key] stands for, or null if it is not one.
  static BillingOwner? tryParse(Object? key) {
    if (key is! String) return null;
    final colon = key.indexOf(':');
    if (colon <= 0 || colon == key.length - 1) return null;
    final id = key.substring(colon + 1);

    return switch (key.substring(0, colon)) {
      'user' => BillingOwner.user(id),
      'team' => BillingOwner.team(id),
      _ => null,
    };
  }
}
