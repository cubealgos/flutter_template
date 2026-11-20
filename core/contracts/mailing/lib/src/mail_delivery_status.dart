/// Where a mail got to. Only what the provider reports is ever claimed:
/// plain SMTP can say [accepted] or [rejected] at send time, never
/// [delivered], and learns of a [bounced] mail only when a clone wires its
/// provider's bounce feed to `Mailer.recordBounce`.
enum MailDeliveryStatus {
  /// The send was claimed but no outcome is stored yet (a crash, or in
  /// flight). A retry does not send again.
  pending,

  /// The provider took the mail for delivery.
  accepted,

  /// The provider reports the mail delivered (Appwrite Messaging's `sent`).
  delivered,

  /// The provider refused the mail for good (a permanent SMTP failure).
  rejected,

  /// The send failed and its outcome is unknown or definitely not sent; see
  /// `MailDeliveryResult.detail`.
  failed,

  /// The mail came back undeliverable. The recipient is suppressed.
  bounced,

  /// Not sent: the recipient unsubscribed from this mail's subscription or
  /// bounced earlier.
  suppressed,
}
