/// A link into the provider's customer portal. It is temporary and
/// authenticated for the customer: open it at once, never store it.
class PortalSession {
  /// Creates a session.
  const PortalSession({required this.url});

  /// The portal's home, or a subscription's own page.
  final Uri url;
}
