import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teams/teams.dart';

// A test double named for what it is, not for the file.
// ignore: solid_lints/prefer_match_file_name
class _ScriptedGateway implements TeamFunctionGateway {
  _ScriptedGateway(this._respond);

  final ({int statusCode, String body}) Function(Map<String, dynamic>) _respond;
  final List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];

  @override
  Future<({int statusCode, String body})> execute(
    Map<String, dynamic> fields,
  ) async {
    requests.add(fields);

    return _respond(fields);
  }
}

({int statusCode, String body}) _ok(Object? result) => (
  statusCode: _okStatus,
  body: jsonEncode(<String, dynamic>{'result': result}),
);

const int _okStatus = 200;
const int _serverError = 500;
const int _unauthorized = 401;

void main() {
  test('sends the action and its arguments, decodes the result', () async {
    final gateway = _ScriptedGateway(
      (_) => _ok(TeamWire.encodeTeam(const Team(id: 't1', name: 'Acme'))),
    );

    final team = await AppwriteTeamService.withGateway(gateway)
        .createTeam('Acme');

    expect(team.id, 't1');
    expect(team.name, 'Acme');
    expect(gateway.requests.single, <String, dynamic>{
      'op': 'createTeam',
      'name': 'Acme',
    });
  });

  test('transferOwnership names the new owner', () async {
    final gateway = _ScriptedGateway((_) => _ok(null));

    await AppwriteTeamService.withGateway(gateway)
        .transferOwnership('t1', toUserId: 'u2');

    expect(gateway.requests.single, <String, dynamic>{
      'op': 'transferOwnership',
      'teamId': 't1',
      'toUserId': 'u2',
    });
  });

  test('every wire error code comes back as its typed TeamError', () async {
    for (final error in const <TeamError>[
      TeamNotFoundError('m'),
      TeamPermissionError('m'),
      TeamInvariantError('m'),
      TeamInvitationError('m'),
      TeamUnauthenticatedError('m'),
    ]) {
      final service = AppwriteTeamService.withGateway(
        _ScriptedGateway(
          (_) => (
            statusCode: TeamWire.statusFor(error),
            body: jsonEncode(TeamWire.encodeError(error)),
          ),
        ),
      );

      await expectLater(
        service.listTeams,
        throwsA(
          isA<TeamError>().having(
            (e) => e.runtimeType,
            'type',
            error.runtimeType,
          ),
        ),
      );
    }
  });

  test('an empty or unreadable failure body is a TeamUnknownError', () async {
    final service = AppwriteTeamService.withGateway(
      _ScriptedGateway((_) => (statusCode: _serverError, body: '')),
    );

    await expectLater(service.listTeams, throwsA(isA<TeamUnknownError>()));
  });

  test('a transport failure maps to network/unauthenticated errors', () async {
    final offline = AppwriteTeamService.withGateway(
      _FailingGateway(AppwriteException('offline')),
    );
    final signedOut = AppwriteTeamService.withGateway(
      _FailingGateway(AppwriteException('no session', _unauthorized)),
    );

    await expectLater(offline.listTeams, throwsA(isA<TeamNetworkError>()));
    await expectLater(
      signedOut.listTeams,
      throwsA(isA<TeamUnauthenticatedError>()),
    );
  });
}

class _FailingGateway implements TeamFunctionGateway {
  _FailingGateway(this.error);

  final AppwriteException error;

  @override
  Future<({int statusCode, String body})> execute(
    Map<String, dynamic> fields,
  ) => Future.error(error);
}
