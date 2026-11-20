import 'package:billing/src/divergence.dart';

/// What one reconciliation run saw.
class ReconcileReport {
  /// Creates a report.
  const ReconcileReport({required this.checked, required this.divergences});

  /// Subscriptions compared.
  final int checked;

  /// Every difference found.
  final List<Divergence> divergences;
}
