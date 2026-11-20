/// What happened in a `MembershipEvent`.
enum MembershipEventType {
  /// A team was created; its creator became the owner.
  teamCreated,

  /// Someone was invited.
  invited,

  /// An invitee accepted and joined.
  accepted,

  /// An invitation was withdrawn.
  revoked,

  /// An invitation lapsed unaccepted (recorded by `TeamEngine.systemActorId`).
  expired,

  /// A member's role changed.
  roleChanged,

  /// A member was removed by someone else.
  removed,

  /// A member left on their own.
  left,

  /// Ownership moved from one member to another.
  ownershipTransferred,
}
