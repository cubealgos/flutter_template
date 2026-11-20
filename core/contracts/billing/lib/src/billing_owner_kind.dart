/// Who a subscription belongs to.
enum BillingOwnerKind {
  /// One signed-in person.
  user,

  /// A team (an agency or organisation, say): every member shares it.
  team,
}
