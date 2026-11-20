import 'dart:io';

import 'package:api/src/actions/team_admin/native_team_roles.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart' as models;
import 'package:teams/teams.dart';

/// The page size every list call asks for; Appwrite's own maximum.
const int _pageSize = 100;

/// The [TeamStore] over Appwrite: memberships are the native team
/// memberships (so `Role.team(teamId, role)` row permissions follow them),
/// invitations and history are rows of the `serverOnly` tables.
///
/// Built from the per-execution API key (see `lib/main.dart`), so it acts
/// with the Function's scopes, never a member's rights. A membership's
/// native roles are `TeamRoles.implied` of its role run through
/// `nativeTeamRole`: the owner holds `tenant_owner`, `admin` and `member`,
/// and nobody ever holds Appwrite's own `owner` role (see
/// `nativeOwnerRole`).
class AppwriteTeamStore implements TeamStore {
  /// Creates a store over [client], keeping invitations and history in
  /// [databaseId].
  AppwriteTeamStore({required Client client, required this.databaseId})
    : _teams = Teams(client),
      _users = Users(client),
      _tablesDb = TablesDB(client);

  /// The tables' database.
  final String databaseId;

  /// The invitations table.
  static const String invitationsTable = 'team_invitations';

  /// The history table.
  static const String eventsTable = 'team_membership_events';

  final Teams _teams;
  final Users _users;
  final TablesDB _tablesDb;

  @override
  Future<void> saveTeam(Team team) async {
    try {
      await _teams.create(teamId: team.id, name: team.name);
    } on AppwriteException catch (e) {
      if (e.code != HttpStatus.conflict) rethrow;
      await _teams.updateName(teamId: team.id, name: team.name);
    }
  }

  @override
  Future<Team?> findTeam(String teamId) async {
    try {
      final team = await _teams.get(teamId: teamId);

      return Team(id: team.$id, name: team.name);
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.notFound) return null;
      rethrow;
    }
  }

  @override
  Future<void> saveMembership(Membership membership) async {
    final roles = nativeRolesFor(membership.role);
    final existing = await _nativeMembership(
      membership.teamId,
      membership.userId,
    );
    if (existing == null) {
      await _teams.createMembership(
        teamId: membership.teamId,
        roles: roles,
        userId: membership.userId,
      );
    } else {
      await _teams.updateMembership(
        teamId: membership.teamId,
        membershipId: existing.$id,
        roles: roles,
      );
    }
  }

  @override
  Future<void> deleteMembership(String teamId, String userId) async {
    final existing = await _nativeMembership(teamId, userId);
    if (existing == null) return;
    await _teams.deleteMembership(teamId: teamId, membershipId: existing.$id);
  }

  @override
  Future<List<Membership>> membershipsOfTeam(String teamId) async {
    final result = <Membership>[];
    String? after;
    while (true) {
      final page = await _teams.listMemberships(
        teamId: teamId,
        queries: <String>[
          Query.limit(_pageSize),
          if (after != null) Query.cursorAfter(after),
        ],
      );
      result.addAll(
        page.memberships.where((m) => m.confirm).map(_toMembership),
      );
      if (page.memberships.length < _pageSize) return result;
      after = page.memberships.last.$id;
    }
  }

  @override
  Future<List<Membership>> membershipsOfUser(String userId) async {
    final result = <Membership>[];
    String? after;
    while (true) {
      final page = await _users.listMemberships(
        userId: userId,
        queries: <String>[
          Query.limit(_pageSize),
          if (after != null) Query.cursorAfter(after),
        ],
      );
      result.addAll(
        page.memberships.where((m) => m.confirm).map(_toMembership),
      );
      if (page.memberships.length < _pageSize) return result;
      after = page.memberships.last.$id;
    }
  }

  @override
  Future<void> saveInvitation(Invitation invitation) async {
    await _tablesDb.upsertRow(
      databaseId: databaseId,
      tableId: invitationsTable,
      rowId: invitation.id,
      data: _columns(TeamWire.encodeInvitation(invitation)),
    );
  }

  @override
  Future<Invitation?> findInvitation(String invitationId) async {
    try {
      final row = await _tablesDb.getRow(
        databaseId: databaseId,
        tableId: invitationsTable,
        rowId: invitationId,
      );

      return TeamWire.decodeInvitation(_wire(row));
    } on AppwriteException catch (e) {
      if (e.code == HttpStatus.notFound) return null;
      rethrow;
    }
  }

  @override
  Future<List<Invitation>> invitationsOfTeam(String teamId) =>
      _invitationsWhere('teamId', teamId);

  @override
  Future<List<Invitation>> invitationsForEmail(String email) =>
      _invitationsWhere('email', email);

  Future<List<Invitation>> _invitationsWhere(
    String column,
    String value,
  ) async {
    final rows = await _rows(invitationsTable, column, value);

    return rows.map(_wire).map(TeamWire.decodeInvitation).toList();
  }

  @override
  Future<void> appendEvent(MembershipEvent event) async {
    await _tablesDb.createRow(
      databaseId: databaseId,
      tableId: eventsTable,
      rowId: event.id,
      data: _columns(TeamWire.encodeEvent(event)),
    );
  }

  @override
  Future<List<MembershipEvent>> eventsOfTeam(String teamId) async {
    final rows = await _rows(eventsTable, 'teamId', teamId);
    // Oldest first; the row sequence breaks ties between events in one
    // millisecond.
    rows.sort((a, b) {
      final byTime = (a.data['at'] as String).compareTo(b.data['at'] as String);
      if (byTime != 0) return byTime;

      return (int.tryParse(a.$sequence) ?? 0).compareTo(
        int.tryParse(b.$sequence) ?? 0,
      );
    });

    return rows.map(_wire).map(TeamWire.decodeEvent).toList();
  }

  @override
  Future<int> redactEventEmails({
    required DateTime before,
    required String marker,
  }) async {
    var changed = 0;
    String? after;
    while (true) {
      final page = await _tablesDb.listRows(
        databaseId: databaseId,
        tableId: eventsTable,
        queries: <String>[
          Query.lessThan('at', before.toUtc().toIso8601String()),
          Query.limit(_pageSize),
          if (after != null) Query.cursorAfter(after),
        ],
      );
      for (final row in page.rows) {
        final data = <String, dynamic>{
          for (final column in const <String>['actorEmail', 'subjectEmail'])
            if (row.data[column] != null && row.data[column] != marker)
              column: marker,
        };
        if (data.isEmpty) continue;
        await _tablesDb.updateRow(
          databaseId: databaseId,
          tableId: eventsTable,
          rowId: row.$id,
          data: data,
        );
        changed++;
      }
      if (page.rows.length < _pageSize) return changed;
      after = page.rows.last.$id;
    }
  }

  Future<List<models.Row>> _rows(
    String tableId,
    String column,
    String value,
  ) async {
    final result = <models.Row>[];
    String? after;
    while (true) {
      final page = await _tablesDb.listRows(
        databaseId: databaseId,
        tableId: tableId,
        queries: <String>[
          Query.equal(column, value),
          Query.limit(_pageSize),
          if (after != null) Query.cursorAfter(after),
        ],
      );
      result.addAll(page.rows);
      if (page.rows.length < _pageSize) return result;
      after = page.rows.last.$id;
    }
  }

  Future<models.Membership?> _nativeMembership(
    String teamId,
    String userId,
  ) async {
    final page = await _teams.listMemberships(
      teamId: teamId,
      queries: <String>[Query.equal('userId', userId), Query.limit(1)],
    );

    return page.memberships.isEmpty ? null : page.memberships.first;
  }

  Membership _toMembership(models.Membership m) => Membership(
    teamId: m.teamId,
    userId: m.userId,
    email: m.userEmail.toLowerCase(),
    role: contractRoleOf(m.roles),
    joinedAt: DateTime.tryParse(m.joined) ?? DateTime.parse(m.$createdAt),
    membershipId: m.$id,
  );

  /// A table row's columns: the wire encoding without its `id`, which is
  /// the row ID.
  Map<String, dynamic> _columns(Map<String, dynamic> encoded) =>
      <String, dynamic>{...encoded}..remove('id');

  /// The wire form of [row]: its columns plus the row ID as `id`.
  Map<String, dynamic> _wire(models.Row row) => <String, dynamic>{
    ...row.data,
    'id': row.$id,
  };
}
