import 'package:mailing/src/invalid_unsubscribe_reason.dart';

/// Thrown by `UnsubscribeLinks.verify` for a link that must not be honoured.
final class InvalidUnsubscribeLinkError implements Exception {
  /// Creates the error.
  const InvalidUnsubscribeLinkError(this.reason);

  /// The category; the message never says more than this to a caller.
  final InvalidUnsubscribeReason reason;

  @override
  String toString() => 'InvalidUnsubscribeLinkError: ${reason.name}';
}
