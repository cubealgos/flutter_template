/// Who a mail goes to: one Appwrite-style user ID and the address to use.
class MailRecipient {
  /// Creates a recipient.
  const MailRecipient({required this.userId, required this.email});

  /// The user's ID. Suppressions and the delivery record are keyed on it, and
  /// an unsubscribe link is scoped to it. The address is never stored.
  final String userId;

  /// The address to send to.
  final String email;
}
