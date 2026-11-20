/// A checkout the provider hosts.
class CheckoutSession {
  /// Creates a session.
  const CheckoutSession({required this.url, required this.transactionId});

  /// Where to send the buyer.
  final Uri url;

  /// The provider's transaction ID, for support and tests.
  final String transactionId;
}
