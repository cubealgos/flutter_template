import 'package:teams/src/invitation.dart';
import 'package:teams/src/membership.dart';
import 'package:teams/src/membership_event.dart';
import 'package:teams/src/team.dart';
import 'package:teams/src/team_actor.dart';
import 'package:teams/src/team_engine.dart';
import 'package:teams/src/team_error.dart';
import 'package:teams/src/team_service.dart';

/// An in-memory [TeamService] for screens and tests, acting as one user of a
/// `FakeTeamBackend` (make it with `FakeTeamBackend.serviceFor`).
///
/// A thin shell: every rule, including "exactly one owner", is
/// `TeamEngine`'s, the same code the real backend runs.
class FakeTeamService implements TeamService {
  /// Creates a service running `engine` as the user `resolveActor` returns.
  FakeTeamService(this._engine, this._resolveActor);

  final TeamEngine _engine;
  final Future<TeamActor?> Function() _resolveActor;

  /// Resolves the actor, then runs [operation] with it.
  Future<T> _run<T>(Future<T> Function(TeamActor actor) operation) async {
    final actor = await _resolveActor();
    if (actor == null) throw const TeamUnauthenticatedError('No current user.');

    return await operation(actor);
  }

  @override
  Future<Team> createTeam(String name) =>
      _run((actor) => _engine.createTeam(actor, name));

  @override
  Future<List<Team>> listTeams() => _run(_engine.listTeams);

  @override
  Future<List<Membership>> listMembers(String teamId) =>
      _run((actor) => _engine.listMembers(actor, teamId));

  @override
  Future<Invitation> invite(
    String teamId, {
    required String email,
    required String role,
  }) =>
      _run((actor) => _engine.invite(actor, teamId, email: email, role: role));

  @override
  Future<List<Invitation>> listInvitations(String teamId) =>
      _run((actor) => _engine.listInvitations(actor, teamId));

  @override
  Future<List<Invitation>> listMyInvitations() =>
      _run(_engine.listMyInvitations);

  @override
  Future<Membership> acceptInvitation(String invitationId) =>
      _run((actor) => _engine.acceptInvitation(actor, invitationId));

  @override
  Future<void> revokeInvitation(String invitationId) =>
      _run((actor) => _engine.revokeInvitation(actor, invitationId));

  @override
  Future<void> removeMember(String teamId, {required String userId}) =>
      _run((actor) => _engine.removeMember(actor, teamId, userId: userId));

  @override
  Future<void> leaveTeam(String teamId) =>
      _run((actor) => _engine.leaveTeam(actor, teamId));

  @override
  Future<Membership> changeRole(
    String teamId, {
    required String userId,
    required String role,
  }) => _run(
    (actor) => _engine.changeRole(actor, teamId, userId: userId, role: role),
  );

  @override
  Future<void> transferOwnership(String teamId, {required String toUserId}) =>
      _run(
        (actor) => _engine.transferOwnership(actor, teamId, toUserId: toUserId),
      );

  @override
  Future<List<MembershipEvent>> history(String teamId) =>
      _run((actor) => _engine.history(actor, teamId));
}
