import 'package:teams/src/fake_team_service.dart';
import 'package:teams/src/in_memory_team_store.dart';
import 'package:teams/src/team_actor.dart';
import 'package:teams/src/team_directory.dart';
import 'package:teams/src/team_engine.dart';
import 'package:teams/src/team_roles.dart';

/// A mutable clock, so a test can move the backend's time forward.
class _FakeClock {
  _FakeClock(this.now);

  DateTime now;
}

/// A whole fake tenancy backend: the shared state several fake users act on.
///
/// One backend holds every team; [serviceFor] gives a `TeamService` for one
/// signed-in user, so a test can have Ada and Grace act on the same teams. It
/// is also the [TeamDirectory] a `FakeDocumentRepository` asks, which is how
/// the fake mirrors Appwrite's team-scoped row visibility.
class FakeTeamBackend implements TeamDirectory {
  /// Creates an empty backend whose clock starts at [startedAt] (a fixed
  /// instant by default, so tests are deterministic).
  FakeTeamBackend({
    DateTime? startedAt,
    Duration invitationLifetime = const Duration(days: 7),
    Set<String> assignableRoles = const <String>{
      TeamRoles.admin,
      TeamRoles.member,
    },
  }) : this._(
         InMemoryTeamStore(),
         _FakeClock(startedAt ?? DateTime.utc(2026)),
         invitationLifetime,
         assignableRoles,
       );

  FakeTeamBackend._(
    this.store,
    this._clock,
    Duration invitationLifetime,
    Set<String> assignableRoles,
  ) : engine = TeamEngine(
        store: store,
        clock: () => _clock.now,
        invitationLifetime: invitationLifetime,
        assignableRoles: assignableRoles,
      );

  /// The state.
  final InMemoryTeamStore store;

  /// The rules, run on [store].
  final TeamEngine engine;

  final _FakeClock _clock;

  /// The backend's current time.
  DateTime get now => _clock.now;

  /// Moves the backend's clock forward by [duration] (to expire an
  /// invitation, say).
  void advance(Duration duration) => _clock.now = _clock.now.add(duration);

  /// A `TeamService` acting as [actor].
  FakeTeamService serviceFor(TeamActor actor) =>
      FakeTeamService(engine, () async => actor);

  /// A `TeamService` acting as whoever [resolveActor] returns at call time
  /// (null means signed out), for an app wiring it to its `AuthService`.
  FakeTeamService serviceForSession(
    Future<TeamActor?> Function() resolveActor,
  ) => FakeTeamService(engine, resolveActor);

  /// The display names of the teams [userId] owns (see
  /// `TeamEngine.ownedTeams`): what the fake account deletion refuses on,
  /// mirroring the real `delete_account` action.
  Future<List<String>> ownedTeamNames(String userId) async => [
    for (final team in await engine.ownedTeams(userId)) team.name,
  ];

  /// Drops every membership of [userId], as deleting an Appwrite user does.
  /// The history is left alone: it is append-only and outlives membership.
  Future<void> forgetUser(String userId) async {
    for (final m in await store.membershipsOfUser(userId)) {
      await store.deleteMembership(m.teamId, userId);
    }
  }

  @override
  Future<Set<String>> rolesOf({
    required String userId,
    required String teamId,
  }) async {
    for (final m in await store.membershipsOfTeam(teamId)) {
      if (m.userId == userId) return TeamRoles.implied(m.role);
    }

    return const <String>{};
  }
}
