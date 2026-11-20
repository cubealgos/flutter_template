import 'package:app/app/active_team_service.dart';
import 'package:auth/auth.dart';
import 'package:billing/billing.dart';
import 'package:injectable/injectable.dart';
import 'package:teams/teams.dart';

/// Who the signed-in user bills as: **team-first**. If the active team is one
/// the user still belongs to, the subscription is the team's (every member
/// shares it); otherwise it is the user's own. Null when nobody is signed in.
@lazySingleton
class BillingOwnerResolver {
  /// Creates the resolver.
  BillingOwnerResolver(this._auth, this._teams, this._active);

  final AuthService _auth;
  final TeamService _teams;
  final ActiveTeamService _active;

  /// The owner to bill, or null with no session.
  Future<BillingOwner?> resolve() async {
    final session = _auth.currentSession;
    if (session == null) return null;
    final stored = await _active.activeTeamId();
    if (stored != null) {
      try {
        final teams = await _teams.listTeams();
        if (teams.any((t) => t.id == stored)) return BillingOwner.team(stored);
      } on TeamError {
        // Offline or refused: bill the user rather than guess a team.
      }
    }

    return BillingOwner.user(session.userId);
  }
}
