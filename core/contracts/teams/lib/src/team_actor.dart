/// Who is calling a `TeamEngine` operation.
class TeamActor {
  /// Creates an actor.
  const TeamActor({required this.userId, required this.email});

  /// The caller's user ID.
  final String userId;

  /// The caller's verified email; invitations are matched against it.
  final String email;
}
