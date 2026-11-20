/// Why a billing operation failed, with the HTTP status the `billing` action
/// answers it with.
sealed class BillingError implements Exception {
  const BillingError(this.code, this.message, this.statusCode);

  /// A stable machine-readable code.
  final String code;

  /// A message safe to show.
  final String message;

  /// The HTTP status.
  final int statusCode;

  @override
  String toString() => 'BillingError($code): $message';
}

/// The request is malformed (an empty plan, a quantity below one).
final class BillingInvalidError extends BillingError {
  /// Creates the error.
  const BillingInvalidError(String message)
    : super('invalid_request', message, 400);
}

/// The caller may not do this for that owner.
final class BillingForbiddenError extends BillingError {
  /// Creates the error.
  const BillingForbiddenError(String message)
    : super('forbidden', message, 403);
}

/// The owner has no subscription to act on.
final class BillingNoSubscriptionError extends BillingError {
  /// Creates the error.
  const BillingNoSubscriptionError()
    : super('no_subscription', 'There is no subscription to change.', 404);
}

/// The plan is not one the product sells.
final class BillingUnknownPlanError extends BillingError {
  /// Creates the error.
  const BillingUnknownPlanError(String plan)
    : super('unknown_plan', 'Unknown plan "$plan".', 400);
}

/// Billing is not set up (no provider key or plan list).
final class BillingNotConfiguredError extends BillingError {
  /// Creates the error.
  const BillingNotConfiguredError()
    : super('not_configured', 'Billing is not configured.', 503);
}

/// The provider refused or failed the call.
final class BillingProviderError extends BillingError {
  /// Creates the error.
  const BillingProviderError(String message)
    : super('provider_error', message, 502);
}
