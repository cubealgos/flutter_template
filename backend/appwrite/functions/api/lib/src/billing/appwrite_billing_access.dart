import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:billing/billing.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:paddle_billing/paddle_billing.dart';
import 'package:teams/teams.dart';

/// Looks up the native roles of a user in a team, or null if not a member.
typedef RolesLookup =
    Future<List<String>?> Function(String teamId, String userId);

Future<List<String>?> _teamsRoles(
  Teams teams,
  String teamId,
  String userId,
) async {
  final page = await teams.listMemberships(
    teamId: teamId,
    queries: <String>[
      Query.equal('userId', <String>[userId]),
    ],
  );

  return page.memberships.isEmpty ? null : page.memberships.first.roles;
}

/// HTTP 404.
const int _notFound = 404;

/// [BillingAccess] over Appwrite Teams: a user acts for themselves; for a
/// team, any member reads and the owner or an admin manages. The membership
/// is read with the execution's key, for the caller's user ID the router took
/// from the unforgeable `x-appwrite-user-id` header.
///
/// **A team that does not exist is a non-member, not a failure:** Appwrite's
/// Memberships XList.php (tag 2.3.0) throws `TEAM_NOT_FOUND` (404) for an
/// unknown team ID, while a real team the caller is not in simply lists no
/// membership for them. Both mean "refuse with 403"; any other Appwrite error
/// is a genuine failure and propagates.
class AppwriteBillingAccess implements BillingAccess {
  /// Creates the check over [client].
  AppwriteBillingAccess(Client client)
    : this.withLookup(
        (teamId, userId) => _teamsRoles(Teams(client), teamId, userId),
      );

  /// Creates the check over a roles lookup, for tests.
  AppwriteBillingAccess.withLookup(this._lookup);

  final RolesLookup _lookup;

  @override
  Future<bool> mayManage(String userId, BillingOwner owner) async {
    if (owner.kind == BillingOwnerKind.user) return owner.id == userId;
    final roles = await _rolesIn(owner.id, userId);

    // The owner holds `admin` too (`TeamRoles.implied`), under the native
    // owner role's own name.
    return roles != null &&
        (roles.contains(nativeOwnerRole) || roles.contains(TeamRoles.admin));
  }

  @override
  Future<bool> mayRead(String userId, BillingOwner owner) async {
    if (owner.kind == BillingOwnerKind.user) return owner.id == userId;

    return await _rolesIn(owner.id, userId) != null;
  }

  Future<List<String>?> _rolesIn(String teamId, String userId) async {
    try {
      return await _lookup(teamId, userId);
    } on AppwriteException catch (e) {
      if (e.code == _notFound) return null;
      rethrow;
    }
  }
}
