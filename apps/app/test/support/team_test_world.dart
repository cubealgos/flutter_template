import 'package:app/app/active_team_service.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:teams/teams.dart';

/// A fake tenancy backend plus per-user `FakeAuthService`s, so a test can
/// act as Ada in a controller while Grace invites her from "another
/// device".
class TeamTestWorld {
  /// Creates a world with Ada and Grace.
  factory TeamTestWorld() {
    final backend = FakeTeamBackend();

    return TeamTestWorld._(
      backend,
      _user(backend, 'ada-id', 'ada@example.com'),
      _user(backend, 'grace-id', 'grace@example.com'),
    );
  }

  TeamTestWorld._(this.backend, this.ada, this.grace);

  /// The shared tenancy state.
  final FakeTeamBackend backend;

  /// Ada's side.
  final TeamTestUser ada;

  /// Grace's side.
  final TeamTestUser grace;

  static TeamTestUser _user(
    FakeTeamBackend backend,
    String userId,
    String email,
  ) => TeamTestUser(
    userId: userId,
    email: email,
    auth: FakeAuthService(
      persistedSession: AuthSession(userId: userId, email: email),
      ownedTeamNames: backend.ownedTeamNames,
      onAccountDeleted: backend.forgetUser,
    ),
    teams: backend.serviceFor(TeamActor(userId: userId, email: email)),
    active: ActiveTeamService(FakeUserPreferences()),
  );
}

/// One user's services in a [TeamTestWorld].
class TeamTestUser {
  /// Creates the bundle.
  TeamTestUser({
    required this.userId,
    required this.email,
    required this.auth,
    required this.teams,
    required this.active,
  });

  /// The user's ID.
  final String userId;

  /// The user's email.
  final String email;

  /// Their auth service (signed in once restored).
  final FakeAuthService auth;

  /// Their team service.
  final FakeTeamService teams;

  /// Their active-team preference.
  final ActiveTeamService active;
}
