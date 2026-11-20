/// What `BillingEngine.process` did with an event.
enum WebhookStatus {
  /// At least one row was new: it was recorded and applied.
  accepted,

  /// Every row already existed: the event was seen before and nothing
  /// changed.
  replayed,
}
