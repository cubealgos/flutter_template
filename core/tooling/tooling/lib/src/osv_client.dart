import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/retrying_http.dart';

/// OSV's documented cap on queries per `/v1/querybatch` request.
const int _maxBatch = 1000;

/// A package at a resolved version, as OSV is asked about it.
typedef PubPackageVersion = ({String name, String version});

/// Talks to the public OSV API (https://google.github.io/osv.dev/api/), no
/// account or key: `POST /v1/querybatch` lists the advisory ids affecting
/// each (package, version) in ecosystem `Pub`, and `GET /v1/vulns/<id>`
/// returns an advisory's full record (severity, aliases, summary).
///
/// Network behaviour is shared with the pub.dev client through
/// `RetryingHttp`: one keep-alive connection, retries with backoff on
/// transient failures, injectable client/delay/log.
class OsvClient {
  /// Creates a client. Pass `httpClient` in tests; call [close] when done.
  /// `baseUrl` is overridable for tests only.
  OsvClient({
    http.Client? httpClient,
    Future<void> Function(Duration)? delay,
    Random? random,
    void Function(String)? log,
    this._baseUrl = 'https://api.osv.dev',
    int maxAttempts = 5,
    Duration baseDelay = const Duration(milliseconds: 500),
  }) : _http = RetryingHttp(
         service: 'OSV',
         httpClient: httpClient,
         delay: delay,
         random: random,
         log: log ?? stderr.writeln,
         maxAttempts: maxAttempts,
         baseDelay: baseDelay,
       );

  final String _baseUrl;
  final RetryingHttp _http;
  final Map<String, Map<String, dynamic>> _vulnCache = {};

  /// Closes the underlying HTTP client.
  void close() => _http.close();

  /// For each of [packages] (same order), the ids of every advisory OSV
  /// lists against that exact version. Follows `next_page_token` until a
  /// package's list is complete.
  Future<List<List<String>>> advisoryIdsFor(
    List<PubPackageVersion> packages,
  ) async {
    final result = <List<String>>[];
    for (var start = 0; start < packages.length; start += _maxBatch) {
      final chunk = packages.sublist(
        start,
        min(start + _maxBatch, packages.length),
      );
      result.addAll(await _queryChunk(chunk));
    }

    return result;
  }

  Future<List<List<String>>> _queryChunk(List<PubPackageVersion> chunk) async {
    final ids = List.generate(chunk.length, (_) => <String>[]);
    var pending = <int, String?>{
      for (var i = 0; i < chunk.length; i++) i: null,
    };
    while (pending.isNotEmpty) {
      final indexes = pending.keys.toList();
      final results = await _queryPage(chunk, pending);
      final next = <int, String?>{};
      for (var k = 0; k < indexes.length; k++) {
        final entry = results[k];
        if (entry is! Map) continue;
        ids[indexes[k]].addAll(_idsOf(entry['vulns']));
        final token = entry['next_page_token'];
        if (token is String && token.isNotEmpty) next[indexes[k]] = token;
      }
      pending = next;
    }

    return ids;
  }

  /// One `querybatch` request for the [pending] chunk indexes (each with its
  /// page token, if any); returns the per-query results in the same order.
  Future<List<Object?>> _queryPage(
    List<PubPackageVersion> chunk,
    Map<int, String?> pending,
  ) async {
    final body = {
      'queries': [
        for (final entry in pending.entries)
          {
            'package': {'name': chunk[entry.key].name, 'ecosystem': 'Pub'},
            'version': chunk[entry.key].version,
            if (entry.value != null) 'page_token': entry.value,
          },
      ],
    };
    final uri = Uri.parse('$_baseUrl/v1/querybatch');
    final response = await _http.send(
      'a batch of ${pending.length} package(s)',
      uri,
      (client) => client.post(
        uri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    final results = _decodeMap(response.body, 'querybatch')['results'];
    if (results is! List || results.length != pending.length) {
      throw CommandFailure(
        'OSV querybatch answered ${results is List ? results.length : 'no'} '
        'result(s) for ${pending.length} quer(ies).',
      );
    }

    return results;
  }

  static Iterable<String> _idsOf(Object? vulns) => vulns is List
      ? vulns
            .whereType<Map<String, dynamic>>()
            .map((v) => v['id'])
            .whereType<String>()
      : const <String>[];

  /// The full OSV record for advisory [id].
  Future<Map<String, dynamic>> vulnerability(String id) async {
    final cached = _vulnCache[id];
    if (cached != null) return cached;
    final uri = Uri.parse('$_baseUrl/v1/vulns/${Uri.encodeComponent(id)}');
    final response = await _http.send(id, uri, (client) => client.get(uri));

    return _vulnCache[id] = _decodeMap(response.body, id);
  }

  Map<String, dynamic> _decodeMap(String body, String what) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (e) {
      throw CommandFailure('OSV response for $what: $e');
    }
    if (decoded is! Map<String, dynamic>) {
      throw CommandFailure('OSV response for $what is not a JSON object.');
    }

    return decoded;
  }
}
