import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/src/appwrite_team_function_gateway.dart';
import 'package:appwrite_adapters/src/team_function_gateway.dart';
import 'package:teams/teams.dart';

/// The HTTP status at or above which a Function response is a failure.
const int _httpErrorStatusStart = 300;

/// The HTTP status Appwrite answers a call with no session.
const int _unauthorizedStatusCode = 401;

/// The [TeamService] backed by the `team_admin` action of the `api` Function.
///
/// **Why a Function, not the Teams SDK directly.** Appwrite Teams has no
/// "exactly one owner" rule and no atomic ownership transfer: a member whose
/// native role is `owner` can invite more owners, demote the only owner, or
/// delete the team, straight through the client SDK. A client can't be
/// trusted to keep that invariant, so every operation (reads included, to
/// keep one code path) runs in `backend/appwrite/functions/api`'s `team_admin`
/// action with
/// `package:teams`'s `TeamEngine`, the same rules `FakeTeamService` runs.
/// Memberships still live in native Appwrite Teams, so row permissions
/// `Role.team(teamId, role)` (see `TeamScope`) follow them.
/// Provisioning never gives anyone the native `owner` role (see
/// `nativeOwnerRole`), so nobody can use the Teams SDK to bypass the
/// Function for a team it manages.
class AppwriteTeamService implements TeamService {
  /// Creates a service calling the Function through [client].
  AppwriteTeamService(Client client)
    : _gateway = AppwriteTeamFunctionGateway(client);

  /// Creates a service over `gateway`, for tests.
  AppwriteTeamService.withGateway(this._gateway);

  final TeamFunctionGateway _gateway;

  @override
  Future<Team> createTeam(String name) async => TeamWire.decodeTeam(
    await _object('createTeam', <String, dynamic>{'name': name}),
  );

  @override
  Future<List<Team>> listTeams() => _list('listTeams', TeamWire.decodeTeam);

  @override
  Future<List<Membership>> listMembers(String teamId) => _list(
    'listMembers',
    TeamWire.decodeMembership,
    <String, dynamic>{'teamId': teamId},
  );

  @override
  Future<Invitation> invite(
    String teamId, {
    required String email,
    required String role,
  }) async => TeamWire.decodeInvitation(
    await _object('invite', <String, dynamic>{
      'teamId': teamId,
      'email': email,
      'role': role,
    }),
  );

  @override
  Future<List<Invitation>> listInvitations(String teamId) => _list(
    'listInvitations',
    TeamWire.decodeInvitation,
    <String, dynamic>{'teamId': teamId},
  );

  @override
  Future<List<Invitation>> listMyInvitations() =>
      _list('listMyInvitations', TeamWire.decodeInvitation);

  @override
  Future<Membership> acceptInvitation(String invitationId) async =>
      TeamWire.decodeMembership(
        await _object('acceptInvitation', <String, dynamic>{
          'invitationId': invitationId,
        }),
      );

  @override
  Future<void> revokeInvitation(String invitationId) async {
    await _call('revokeInvitation', <String, dynamic>{
      'invitationId': invitationId,
    });
  }

  @override
  Future<void> removeMember(String teamId, {required String userId}) async {
    await _call('removeMember', <String, dynamic>{
      'teamId': teamId,
      'userId': userId,
    });
  }

  @override
  Future<void> leaveTeam(String teamId) async {
    await _call('leaveTeam', <String, dynamic>{'teamId': teamId});
  }

  @override
  Future<Membership> changeRole(
    String teamId, {
    required String userId,
    required String role,
  }) async => TeamWire.decodeMembership(
    await _object('changeRole', <String, dynamic>{
      'teamId': teamId,
      'userId': userId,
      'role': role,
    }),
  );

  @override
  Future<void> transferOwnership(
    String teamId, {
    required String toUserId,
  }) async {
    await _call('transferOwnership', <String, dynamic>{
      'teamId': teamId,
      'toUserId': toUserId,
    });
  }

  @override
  Future<List<MembershipEvent>> history(String teamId) => _list(
    'history',
    TeamWire.decodeEvent,
    <String, dynamic>{'teamId': teamId},
  );

  /// [_call] for an action whose result is one JSON object.
  Future<Map<String, dynamic>> _object(
    String action,
    Map<String, dynamic> arguments,
  ) async {
    final result = await _call(action, arguments);
    if (result is Map<String, dynamic>) return result;
    throw TeamUnknownError('team_admin answered $action with no object.');
  }

  /// [_call] for an action whose result is a JSON list, decoded item by item.
  Future<List<T>> _list<T>(
    String action,
    T Function(Map<String, dynamic>) decode, [
    Map<String, dynamic> arguments = const <String, dynamic>{},
  ]) async {
    final result = await _call(action, arguments);
    if (result is! List<dynamic>) {
      throw TeamUnknownError('team_admin answered $action with no list.');
    }

    return <T>[for (final item in result) decode(item as Map<String, dynamic>)];
  }

  /// Runs [action] and returns the response's `result`, or throws the
  /// `TeamError` the Function (or the transport) reported.
  Future<Object?> _call(
    String action, [
    Map<String, dynamic> arguments = const <String, dynamic>{},
  ]) async {
    final ({int statusCode, String body}) response;
    try {
      response = await _gateway.execute(<String, dynamic>{
        'op': action,
        ...arguments,
      });
    } on AppwriteException catch (e) {
      throw _transportError(e);
    }
    final decoded = _decode(response.body);
    if (response.statusCode >= _httpErrorStatusStart) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        throw TeamWire.errorFrom(
          error['code'] as String? ?? 'unknown',
          error['message'] as String? ?? 'Team operation failed.',
        );
      }
      if (response.statusCode == _unauthorizedStatusCode) {
        throw const TeamUnauthenticatedError('No current user.');
      }
      throw TeamUnknownError(
        'team_admin returned ${response.statusCode}: ${response.body}',
      );
    }

    return decoded['result'];
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(body);

      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  TeamError _transportError(AppwriteException e) {
    final message = e.message ?? 'Appwrite error.';
    if (e.code == _unauthorizedStatusCode) {
      return TeamUnauthenticatedError(message);
    }
    // No HTTP status at all means the request never got an answer.
    if (e.code == null || e.code == 0) {
      return TeamNetworkError(message, cause: e);
    }

    return TeamUnknownError(message, cause: e);
  }
}
