import 'package:billing/src/divergence_kind.dart';

/// One difference the reconciler found.
class Divergence {
  /// Creates a divergence.
  const Divergence({
    required this.subscriptionId,
    required this.kind,
    required this.detail,
    required this.corrected,
  });

  /// The subscription.
  final String subscriptionId;

  /// What differs.
  final DivergenceKind kind;

  /// What the two sides said.
  final String detail;

  /// Whether the entitlement was changed to match the provider.
  final bool corrected;

  @override
  String toString() =>
      '$subscriptionId ${kind.name}${corrected ? ' (corrected)' : ''}: $detail';
}
