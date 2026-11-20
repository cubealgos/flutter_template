/// What last wrote a `SubscriptionState`.
enum StateSource {
  /// A provider event, through `BillingEngine`.
  webhook,

  /// A correction from the provider's own data, by `BillingReconciler`.
  reconciler,
}
