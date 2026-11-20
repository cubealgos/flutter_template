import 'package:appwrite/appwrite.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:data/data.dart';

/// The Appwrite permission strings for a new row in [scope], created by
/// [userId].
///
/// A [UserScope] row grants read/update/delete to `Role.user(userId)`. A
/// [TeamScope] row grants them to `Role.team(teamId)` (every member) or, per
/// role, to `Role.team(teamId, role)` for each role in the set, with the
/// owner role run through `nativeTeamRole` so it matches what
/// `backend/appwrite/functions/team_admin` writes onto memberships. Update
/// and delete follow `TeamScope.writeRoles`, defaulting to the read roles.
List<String> appwritePermissionsFor(DocumentScope scope, String userId) =>
    switch (scope) {
      UserScope() => _grant(
        <String>[Role.user(userId)],
        <String>[Role.user(userId)],
      ),
      TeamScope(:final teamId, :final readRoles, :final writeRoles) => _grant(
        _teamRoles(teamId, readRoles),
        _teamRoles(teamId, writeRoles ?? readRoles),
      ),
    };

List<String> _teamRoles(String teamId, Set<String>? roles) => roles == null
    ? <String>[Role.team(teamId)]
    : <String>[for (final r in roles) Role.team(teamId, nativeTeamRole(r))];

List<String> _grant(List<String> readers, List<String> writers) => <String>[
  for (final role in readers) Permission.read(role),
  for (final role in writers) ...<String>[
    Permission.update(role),
    Permission.delete(role),
  ],
];
