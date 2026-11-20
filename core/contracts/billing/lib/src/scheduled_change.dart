import 'package:billing/src/scheduled_action.dart';
import 'package:meta/meta.dart';

/// A pending change: [action] takes effect at [effectiveAt].
@immutable
class ScheduledChange {
  /// Creates a scheduled change.
  const ScheduledChange({required this.action, required this.effectiveAt});

  /// What will happen.
  final ScheduledAction action;

  /// When (UTC).
  final DateTime effectiveAt;

  @override
  int get hashCode => Object.hash(action, effectiveAt);

  @override
  bool operator ==(Object other) =>
      other is ScheduledChange &&
      other.action == action &&
      other.effectiveAt == effectiveAt;
}
