/// One call to the `team_admin` action of the `api` Function: the seam
/// `AppwriteTeamService` is unit-tested through, so no live Appwrite is
/// needed.
abstract interface class TeamFunctionGateway {
  /// Executes the action with the body [fields] (`op` plus its arguments)
  /// and returns the action's HTTP status and response body, whether it
  /// succeeded or reported a failure. Throws `AppwriteException` if the
  /// execution itself fails (network, no session).
  Future<({int statusCode, String body})> execute(Map<String, dynamic> fields);
}
