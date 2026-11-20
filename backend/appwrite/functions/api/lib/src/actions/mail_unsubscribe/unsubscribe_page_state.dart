/// The state an unsubscribe page shows.
enum UnsubscribePageState {
  /// Asks the person to confirm (a GET shows this; a prefetcher that follows
  /// the link therefore unsubscribes no one).
  confirm,

  /// Done.
  unsubscribed,

  /// The link is malformed, forged or expired.
  invalid,

  /// The Function is not configured to honour links.
  notConfigured,
}
