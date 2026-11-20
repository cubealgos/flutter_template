/// Where an `Invitation` stands.
enum InvitationStatus {
  /// Sent and still acceptable.
  pending,

  /// The invitee accepted; a `Membership` exists.
  accepted,

  /// A team owner or admin withdrew it before it was accepted.
  revoked,

  /// Its `expiresAt` passed before it was accepted.
  expired,
}
