/// Thrown by `DeletionService.deleteAccount` when the user owns at least one
/// team: deleting the account would leave it without its owner, which the
/// exactly-one-owner invariant forbids. Nothing was deleted.
class AccountOwnsTeamsException implements Exception {
  /// Creates the exception for the teams named [teamNames].
  const AccountOwnsTeamsException(this.teamNames);

  /// The display names of the teams the user owns.
  final List<String> teamNames;

  /// The message the caller is shown, naming the teams.
  String get message =>
      'You own ${teamNames.map((n) => '"$n"').join(', ')}. Transfer '
      'ownership to another member, or delete the '
      '${teamNames.length == 1 ? 'team' : 'teams'}, before deleting your '
      'account.';

  @override
  String toString() => 'AccountOwnsTeamsException($teamNames)';
}
