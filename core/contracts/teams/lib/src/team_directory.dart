/// What a fake `DocumentRepository` needs to know about team membership to
/// mirror the visibility Appwrite computes itself.
///
/// `FakeTeamBackend` implements it.
abstract interface class TeamDirectory {
  /// The roles [userId] holds in [teamId], with implied ones expanded (see
  /// `TeamRoles.implied`); empty if they are not a member.
  Future<Set<String>> rolesOf({required String userId, required String teamId});
}
