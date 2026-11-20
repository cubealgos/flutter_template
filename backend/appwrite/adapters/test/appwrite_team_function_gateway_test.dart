import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:test/test.dart';

import 'fakes/appwrite_model_fixtures.dart';

const int _ok = 200;
const int _forbidden = 403;

AppwriteTeamFunctionGateway _gateway(
  Future<models.Execution> Function(String body) respond, {
  List<String>? sent,
}) => AppwriteTeamFunctionGateway.withApi(
  ApiClient.withExecutor(({
    required functionId,
    required body,
    required headers,
  }) {
    sent?.add(body);

    return respond(body);
  }),
);

void main() {
  test('calls the team_admin action with the operation in op', () async {
    final sent = <String>[];
    final gateway = _gateway(
      (_) async => fakeExecution(status: _ok, body: '{"result":[]}'),
      sent: sent,
    );

    final response = await gateway.execute(<String, dynamic>{
      'op': 'listTeams',
    });

    expect(response.statusCode, _ok);
    expect(response.body, '{"result":[]}');
    expect(sent.single, contains('"action":"team_admin"'));
    expect(sent.single, contains('"op":"listTeams"'));
  });

  test('hands an action failure back with its status and JSON body', () async {
    final gateway = _gateway(
      (_) async => fakeExecution(
        status: _forbidden,
        body: '{"error":{"code":"permission","message":"no"}}',
      ),
    );

    final response = await gateway.execute(<String, dynamic>{'op': 'invite'});

    expect(response.statusCode, _forbidden);
    expect(response.body, contains('"code":"permission"'));
  });

  test('a transport failure still propagates', () async {
    final gateway = _gateway(
      (_) => Future<models.Execution>.error(AppwriteException('offline')),
    );

    await expectLater(
      () => gateway.execute(<String, dynamic>{'op': 'listTeams'}),
      throwsA(isA<AppwriteException>()),
    );
  });
}
