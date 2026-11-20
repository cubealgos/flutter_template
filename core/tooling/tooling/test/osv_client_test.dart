// Fixture data (HTTP statuses, JSON shapes of the OSV API) and fake-client
// callbacks; naming each status or silencing each empty no-op would only add
// noise to the tests.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/no_empty_block, avoid_dynamic_calls

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/osv_client.dart';

void main() {
  test('retries a transient 503 on querybatch, then succeeds', () async {
    var calls = 0;
    final waits = <Duration>[];
    final client = OsvClient(
      httpClient: MockClient((_) async {
        calls++;
        if (calls == 1) return http.Response('busy', 503);

        return http.Response(
          jsonEncode({
            'results': [
              {
                'vulns': [
                  {'id': 'GHSA-x'},
                ],
              },
            ],
          }),
          200,
        );
      }),
      delay: (d) async => waits.add(d),
      log: (_) {},
    );

    final ids = await client.advisoryIdsFor([(name: 'a', version: '1.0.0')]);

    expect(ids, [
      ['GHSA-x'],
    ]);
    expect(calls, 2);
    expect(waits, hasLength(1));
  });

  test('exhausted retries throw a CommandFailure naming OSV', () async {
    final client = OsvClient(
      httpClient: MockClient((_) async => http.Response('down', 503)),
      delay: (_) async {},
      log: (_) {},
      maxAttempts: 2,
    );

    await expectLater(
      client.advisoryIdsFor([(name: 'a', version: '1.0.0')]),
      throwsA(
        isA<CommandFailure>().having(
          (e) => e.message,
          'message',
          contains('OSV'),
        ),
      ),
    );
  });

  test('follows next_page_token', () async {
    final tokens = <String?>[];
    final client = OsvClient(
      httpClient: MockClient((request) async {
        final q = (jsonDecode(request.body)['queries'] as List).single as Map;
        tokens.add(q['page_token'] as String?);
        final first = q['page_token'] == null;

        return http.Response(
          jsonEncode({
            'results': [
              {
                'vulns': [
                  {'id': first ? 'GHSA-1' : 'GHSA-2'},
                ],
                if (first) 'next_page_token': 'tok',
              },
            ],
          }),
          200,
        );
      }),
      log: (_) {},
    );

    expect(await client.advisoryIdsFor([(name: 'a', version: '1')]), [
      ['GHSA-1', 'GHSA-2'],
    ]);
    expect(tokens, [null, 'tok']);
  });

  test('a mismatched result count is a failure, not a silent pass', () async {
    final client = OsvClient(
      httpClient: MockClient(
        (_) async => http.Response('{"results": []}', 200),
      ),
      log: (_) {},
    );

    await expectLater(
      client.advisoryIdsFor([(name: 'a', version: '1')]),
      throwsA(isA<CommandFailure>()),
    );
  });
}
