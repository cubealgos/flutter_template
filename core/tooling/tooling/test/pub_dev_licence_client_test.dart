import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/pub_dev_licence_client.dart';

/// HTTP status codes used by the fake responses below.
const int _statusOk = 200;
const int _statusNotFound = 404;

/// A successful pub.dev score response carrying `license:<tag>` entries for
/// each of [tags].
http.Response _scoreResponse(List<String> tags) => http.Response(
  jsonEncode({'tags': tags.map((t) => 'license:$t').toList()}),
  _statusOk,
);

void main() {
  // Assigned in setUp/read throughout the tests, cleaned up in tearDown —
  // the standard package:test fixture-per-test pattern.
  // ignore: solid_lints/avoid_late_keyword
  late Directory tempDir;

  setUp(() => tempDir = Directory.systemTemp.createTempSync('pub_dev_client_'));
  tearDown(() => tempDir.deleteSync(recursive: true));

  test('fetches, parses license: tags and strips the prefix', () async {
    final requested = <Uri>[];
    final client = PubDevLicenceClient(
      cacheDir: tempDir.path,
      httpClient: MockClient((request) async {
        requested.add(request.url);

        return _scoreResponse(['bsd-3-clause', 'fsf-libre', 'osi-approved']);
      }),
    );

    final licences = await client.licencesFor('some_pkg', '1.0.0');

    expect(licences.rawTagSuffixes, [
      'bsd-3-clause',
      'fsf-libre',
      'osi-approved',
    ]);
    expect(licences.spdxCandidates, ['BSD-3-Clause']);
    expect(
      requested.single,
      Uri.parse('https://pub.dev/api/packages/some_pkg/versions/1.0.0/score'),
    );
  });

  test('caches to disk and does not re-fetch a cached package', () async {
    var fetchCount = 0;
    final mock = MockClient((_) async {
      fetchCount++;

      return _scoreResponse(['mit']);
    });

    final first = PubDevLicenceClient(cacheDir: tempDir.path, httpClient: mock);
    await first.licencesFor('some_pkg', '1.0.0');

    final second = PubDevLicenceClient(
      cacheDir: tempDir.path,
      httpClient: mock,
    );
    final licences = await second.licencesFor('some_pkg', '1.0.0');

    expect(fetchCount, 1);
    expect(licences.spdxCandidates, ['MIT']);
    expect(
      File(p.join(tempDir.path, 'licence_check_cache.json')).existsSync(),
      isTrue,
    );
  });

  test('throws CommandFailure on a non-200 response', () async {
    final client = PubDevLicenceClient(
      cacheDir: tempDir.path,
      httpClient: MockClient(
        (_) async => http.Response('not found', _statusNotFound),
      ),
    );

    await expectLater(
      client.licencesFor('missing_pkg', '1.0.0'),
      throwsA(isA<CommandFailure>()),
    );
  });

  test('throws CommandFailure when the response has no tags list', () async {
    final client = PubDevLicenceClient(
      cacheDir: tempDir.path,
      httpClient: MockClient(
        (_) async => http.Response(jsonEncode({}), _statusOk),
      ),
    );

    await expectLater(
      client.licencesFor('odd_pkg', '1.0.0'),
      throwsA(isA<CommandFailure>()),
    );
  });

  test('a corrupt cache file is ignored, not a hard failure', () async {
    File(p.join(tempDir.path, 'licence_check_cache.json'))
        .writeAsStringSync('not json');

    final client = PubDevLicenceClient(
      cacheDir: tempDir.path,
      httpClient: MockClient((_) async => _scoreResponse(['isc'])),
    );

    final licences = await client.licencesFor('some_pkg', '1.0.0');

    expect(licences.spdxCandidates, ['ISC']);
  });

  test(
    'the cache is per version: a bump misses, the same version hits',
    () async {
      final requested = <Uri>[];
      final client = PubDevLicenceClient(
        cacheDir: tempDir.path,
        httpClient: MockClient((request) async {
          requested.add(request.url);

          return _scoreResponse(['mit']);
        }),
      );

      await client.licencesFor('some_pkg', '1.0.0');
      await client.licencesFor('some_pkg', '1.0.0');
      await client.licencesFor('some_pkg', '1.0.1');

      expect(requested.map((u) => u.path), [
        '/api/packages/some_pkg/versions/1.0.0/score',
        '/api/packages/some_pkg/versions/1.0.1/score',
      ]);
    },
  );

  test('an old-format cache entry (bare name) is ignored', () async {
    File(p.join(tempDir.path, 'licence_check_cache.json')).writeAsStringSync(
      jsonEncode({
        'some_pkg': ['gpl-3.0'],
      }),
    );
    final client = PubDevLicenceClient(
      cacheDir: tempDir.path,
      httpClient: MockClient((_) async => _scoreResponse(['isc'])),
    );

    final licences = await client.licencesFor('some_pkg', '1.0.0');

    expect(licences.spdxCandidates, ['ISC']);
  });

  test(
    'an unanalysed version falls back to the latest score, logged',
    () async {
      final requested = <String>[];
      final logs = <String>[];
      final client = PubDevLicenceClient(
        cacheDir: tempDir.path,
        log: logs.add,
        httpClient: MockClient((request) async {
          requested.add(request.url.path);

          return request.url.path.contains('/versions/')
              ? http.Response(
                  jsonEncode({
                    'tags': ['publisher:x'],
                  }),
                  _statusOk,
                )
              : _scoreResponse(['bsd-3-clause']);
        }),
      );

      final licences = await client.licencesFor('some_pkg', '1.0.0');

      expect(licences.spdxCandidates, ['BSD-3-Clause']);
      expect(requested, [
        '/api/packages/some_pkg/versions/1.0.0/score',
        '/api/packages/some_pkg/score',
      ]);
      expect(logs.single, contains('falling back'));
    },
  );
}
