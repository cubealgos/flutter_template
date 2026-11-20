import 'package:api/src/actions/team_admin/bad_request_error.dart';
import 'package:teams/teams.dart';

/// Reads one named string argument of the request, or throws a
/// [BadRequestError].
typedef ArgumentReader = String Function(String name);

typedef _Action =
    Future<Object?> Function(
      TeamEngine engine,
      TeamActor actor,
      ArgumentReader arg,
    );

List<Map<String, dynamic>> _all<T>(
  List<T> items,
  Map<String, dynamic> Function(T) encode,
) => items.map(encode).toList();

/// Every action the Function answers, by the `op` a request carries. The
/// names are exactly `TeamService`'s method names.
final Map<String, _Action> _actions = <String, _Action>{
  'createTeam': (e, a, arg) async =>
      TeamWire.encodeTeam(await e.createTeam(a, arg('name'))),
  'listTeams': (e, a, _) async =>
      _all(await e.listTeams(a), TeamWire.encodeTeam),
  'listMembers': (e, a, arg) async =>
      _all(await e.listMembers(a, arg('teamId')), TeamWire.encodeMembership),
  'invite': (e, a, arg) async => TeamWire.encodeInvitation(
    await e.invite(a, arg('teamId'), email: arg('email'), role: arg('role')),
  ),
  'listInvitations': (e, a, arg) async => _all(
    await e.listInvitations(a, arg('teamId')),
    TeamWire.encodeInvitation,
  ),
  'listMyInvitations': (e, a, _) async =>
      _all(await e.listMyInvitations(a), TeamWire.encodeInvitation),
  'acceptInvitation': (e, a, arg) async => TeamWire.encodeMembership(
    await e.acceptInvitation(a, arg('invitationId')),
  ),
  'revokeInvitation': (e, a, arg) async {
    await e.revokeInvitation(a, arg('invitationId'));

    return null;
  },
  'removeMember': (e, a, arg) async {
    await e.removeMember(a, arg('teamId'), userId: arg('userId'));

    return null;
  },
  'leaveTeam': (e, a, arg) async {
    await e.leaveTeam(a, arg('teamId'));

    return null;
  },
  'changeRole': (e, a, arg) async => TeamWire.encodeMembership(
    await e.changeRole(
      a,
      arg('teamId'),
      userId: arg('userId'),
      role: arg('role'),
    ),
  ),
  'transferOwnership': (e, a, arg) async {
    await e.transferOwnership(a, arg('teamId'), toUserId: arg('toUserId'));

    return null;
  },
  'history': (e, a, arg) async =>
      _all(await e.history(a, arg('teamId')), TeamWire.encodeEvent),
};

/// Runs the action [name] for [actor] on [engine], reading its arguments
/// from [body]. Returns the JSON-encodable result.
///
/// Throws a [BadRequestError] for an unknown action or a missing/mistyped
/// argument; a `TeamError` propagates as is.
Future<Object?> runTeamAction(
  String name,
  TeamEngine engine,
  TeamActor actor,
  Map<String, dynamic> body,
) {
  final action = _actions[name];
  if (action == null) throw BadRequestError('Unknown action "$name".');

  return action(engine, actor, (argument) {
    final value = body[argument];
    if (value is! String) {
      throw BadRequestError('"$argument" must be a string.');
    }

    return value;
  });
}
