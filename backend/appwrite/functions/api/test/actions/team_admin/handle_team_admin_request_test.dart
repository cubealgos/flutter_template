import 'package:api/src/actions/team_admin/handle_team_admin_request.dart';
import 'package:api/src/actions/team_admin/native_team_roles.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:teams/teams.dart';
import 'package:test/test.dart';

const _users = <String, TeamActor>{
  'ada': TeamActor(userId: 'ada', email: 'ada@example.com'),
  'grace': TeamActor(userId: 'grace', email: 'grace@example.com'),
};

const int httpUnauthorized = 401;
const int httpForbidden = 403;
const int httpNotFound = 404;
const int httpUnprocessable = 422;

// A test fixture named for what it is, not for the file.
// ignore: solid_lints/prefer_match_file_name
class _Harness {
  _Harness() : engine = TeamEngine(store: InMemoryTeamStore());

  final TeamEngine engine;

  Future<TeamActor> _resolve(String userId) async {
    final actor = _users[userId];
    if (actor == null) {
      throw const TeamPermissionError('A verified email address is required.');
    }

    return actor;
  }

  Future<Map<String, dynamic>> call(
    String? caller,
    Map<String, dynamic>? body, {
    int expectedStatus = okStatusCode,
  }) async {
    final response = await handleTeamAdminRequest(
      callerUserId: caller,
      body: body,
      engine: engine,
      resolveActor: _resolve,
    );
    expect(response.statusCode, expectedStatus, reason: '${response.body}');

    return response.body;
  }
}

void main() {
  test('refuses a call with no caller, and a malformed body', () async {
    final h = _Harness();

    await h.call(null, <String, dynamic>{
      'op': 'listTeams',
    }, expectedStatus: httpUnauthorized);
    await h.call('ada', null, expectedStatus: badRequestStatusCode);
    await h.call('ada', <String, dynamic>{
      'op': 'nope',
    }, expectedStatus: badRequestStatusCode);
    await h.call('ada', <String, dynamic>{
      'op': 'listMembers',
    }, expectedStatus: badRequestStatusCode);
  });

  test('refuses a caller whose email cannot be verified', () async {
    final h = _Harness();

    final body = await h.call('mallory', <String, dynamic>{
      'op': 'listTeams',
    }, expectedStatus: httpForbidden);

    expect((body['error'] as Map)['code'], 'permission');
  });

  test('runs a whole team lifecycle over the wire', () async {
    final h = _Harness();
    final created = await h.call('ada', <String, dynamic>{
      'op': 'createTeam',
      'name': 'Acme',
    });
    final teamId = (created['result'] as Map)['id'] as String;
    final invited = await h.call('ada', <String, dynamic>{
      'op': 'invite',
      'teamId': teamId,
      'email': 'grace@example.com',
      'role': 'member',
    });
    final invitationId = (invited['result'] as Map)['id'] as String;
    final mine = await h.call('grace', <String, dynamic>{
      'op': 'listMyInvitations',
    });
    expect(mine['result'], hasLength(1));
    await h.call('grace', <String, dynamic>{
      'op': 'acceptInvitation',
      'invitationId': invitationId,
    });

    await h.call('ada', <String, dynamic>{
      'op': 'transferOwnership',
      'teamId': teamId,
      'toUserId': 'grace',
    });

    final members = await h.call('ada', <String, dynamic>{
      'op': 'listMembers',
      'teamId': teamId,
    });
    final roles = {
      for (final m in members['result'] as List<dynamic>)
        (m as Map)['userId']: m['role'],
    };
    expect(roles, {'ada': 'admin', 'grace': 'owner'});
    final history = await h.call('grace', <String, dynamic>{
      'op': 'history',
      'teamId': teamId,
    });
    final events = history['result'] as List<dynamic>? ?? <dynamic>[];
    expect(
      (events.last as Map<String, dynamic>)['type'],
      'ownershipTransferred',
    );
  });

  test('the owner invariant is enforced for a direct caller too', () async {
    final h = _Harness();
    final created = await h.call('ada', <String, dynamic>{
      'op': 'createTeam',
      'name': 'Acme',
    });
    final teamId = (created['result'] as Map)['id'] as String;

    final body = await h.call('ada', <String, dynamic>{
      'op': 'invite',
      'teamId': teamId,
      'email': 'grace@example.com',
      'role': 'owner',
    }, expectedStatus: httpUnprocessable);
    await h.call('ada', <String, dynamic>{
      'op': 'leaveTeam',
      'teamId': teamId,
    }, expectedStatus: httpUnprocessable);
    await h.call('grace', <String, dynamic>{
      'op': 'listMembers',
      'teamId': teamId,
    }, expectedStatus: httpNotFound);

    expect((body['error'] as Map)['code'], 'invariant');
  });

  group('native roles', () {
    test('the owner is never a native owner, and the mapping round trips', () {
      expect(nativeRolesFor('owner'), isNot(contains('owner')));
      expect(
        nativeRolesFor('owner'),
        containsAll(<String>[nativeOwnerRole, 'admin', 'member']),
      );
      for (final role in ['owner', 'admin', 'member', 'auditor']) {
        expect(contractRoleOf(nativeRolesFor(role)), role);
      }
    });
  });
}
