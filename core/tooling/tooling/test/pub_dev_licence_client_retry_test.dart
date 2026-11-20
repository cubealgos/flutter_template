import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/pub_dev_licence_client.dart';

const int _statusOk = 200;
const int _statusNotFound = 404;
const int _statusServerError = 503;

/// Attempts allowed by the clients built below.
const int _attempts = 3;

http.Response _mit() => http.Response(
  jsonEncode({
    'tags': ['license:mit'],
  }),
  _statusOk,
);

void main() {
  // Assigned in setUp, cleaned up in tearDown (package:test fixture pattern).
  // ignore: solid_lints/avoid_late_keyword
  late Directory tempDir;
  final waits = <Duration>[];
  final logs = <String>[];

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pub_dev_retry_');
    waits.clear();
    logs.clear();
  });
  tearDown(() => tempDir.deleteSync(recursive: true));

  PubDevLicenceClient build(MockClient mock, {int maxAttempts = _attempts}) =>
      PubDevLicenceClient(
        cacheDir: tempDir.path,
        httpClient: mock,
        maxAttempts: maxAttempts,
        delay: (d) async => waits.add(d),
        log: logs.add,
      );

  test('a transient failure is retried, logged, then succeeds', () async {
    var calls = 0;
    final client = build(
      MockClient((_) async {
        calls++;
        if (calls == 1) throw const HandshakeException('dropped');
        if (calls == _attempts - 1) {
          return http.Response('busy', _statusServerError);
        }

        return _mit();
      }),
    );

    final licences = await client.licencesFor('some_pkg', '1.0.0');

    expect(licences.spdxCandidates, ['MIT']);
    expect(calls, _attempts);
    expect(waits, hasLength(_attempts - 1));
    expect(logs, hasLength(_attempts - 1));
    expect(logs.first, allOf(contains('some_pkg'), contains('Handshake')));
  });

  test('exhausted attempts throw a clear CommandFailure', () async {
    var calls = 0;
    final client = build(
      MockClient((_) async {
        calls++;
        throw const SocketException('reset');
      }),
    );

    await expectLater(
      client.licencesFor('some_pkg', '1.0.0'),
      throwsA(
        isA<CommandFailure>().having(
          (e) => e.message,
          'message',
          allOf(contains('some_pkg'), contains('after $_attempts attempts')),
        ),
      ),
    );
    expect(calls, _attempts);
  });

  test('a 404 is not retried', () async {
    var calls = 0;
    final client = build(
      MockClient((_) async {
        calls++;

        return http.Response('nope', _statusNotFound);
      }),
    );

    await expectLater(
      client.licencesFor('missing_pkg', '1.0.0'),
      throwsA(isA<CommandFailure>()),
    );
    expect(calls, 1);
    expect(waits, isEmpty);
  });

  test('a response is cached on arrival, so a failed run resumes', () async {
    final mock = MockClient((request) async {
      if (request.url.pathSegments[2] == 'good') return _mit();

      return http.Response('down', _statusServerError);
    });
    await build(mock, maxAttempts: 1).licencesFor('good', '1.0.0');
    await expectLater(
      build(mock, maxAttempts: 1).licencesFor('bad', '1.0.0'),
      throwsA(isA<CommandFailure>()),
    );

    final resumed = build(
      MockClient((_) async => fail('must come from the cache')),
    );
    expect((await resumed.licencesFor('good', '1.0.0')).spdxCandidates, [
      'MIT',
    ]);
  });
}
