// Fixture data (HTTP statuses, JSON shapes of the OSV API) and fake-client
// callbacks; naming each status or silencing each empty no-op would only add
// noise to the tests.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/no_empty_block, avoid_dynamic_calls

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tooling/src/osv_client.dart';

/// A fake OSV API: [advisoriesByPackage] maps `name@version` to advisory ids,
/// [records] maps an id to its OSV record. Counts requests in [requests].
class FakeOsv {
  FakeOsv({this.advisoriesByPackage = const {}, this.records = const {}});

  final Map<String, List<String>> advisoriesByPackage;
  final Map<String, Map<String, dynamic>> records;
  final List<String> requests = [];

  MockClient get mock => MockClient(_handle);

  OsvClient client() => OsvClient(
    httpClient: mock,
    delay: (_) async {},
    log: (_) {},
    maxAttempts: 2,
  );

  Future<http.Response> _handle(http.Request request) async {
    requests.add('${request.method} ${request.url.path}');
    if (request.url.path == '/v1/querybatch') {
      final queries = (jsonDecode(request.body)['queries'] as List)
          .cast<Map<String, dynamic>>();
      final results = [
        for (final q in queries)
          _resultFor(q['package'] as Map<String, dynamic>, q['version']),
      ];

      return http.Response(jsonEncode({'results': results}), 200);
    }
    final id = request.url.pathSegments.last;
    final record = records[id];

    return record == null
        ? http.Response('{}', 404)
        : http.Response(jsonEncode(record), 200);
  }

  Map<String, dynamic> _resultFor(
    Map<String, dynamic> package,
    Object? version,
  ) {
    final ids = advisoriesByPackage['${package['name']}@$version'] ?? [];

    return {
      if (ids.isNotEmpty)
        'vulns': [
          for (final id in ids) {'id': id, 'modified': '2026-01-01T00:00:00Z'},
        ],
    };
  }
}
