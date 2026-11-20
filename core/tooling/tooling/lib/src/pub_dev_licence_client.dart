import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/licence_policy.dart';
import 'package:tooling/src/retrying_http.dart';

/// Fetches a package's licence tags from pub.dev's score API
/// (`GET https://pub.dev/api/packages/<name>/versions/<version>/score`, whose JSON body has a
/// `tags` array containing entries like `license:bsd-3-clause`,
/// `license:fsf-libre`, `license:osi-approved` — verified by hand against
/// pub.dev for this workspace's own dependency graph),
/// backed by an on-disk JSON cache so repeated local runs don't re-fetch
/// every package on every invocation. The cache has no TTL: a package's
/// published licence essentially never changes without a version bump,
/// and a `LicenceException` is keyed on the licence precisely so a change
/// that does happen re-refuses rather than silently staying exempted —
/// see `licence_exception.dart`. Delete the cache file to force a
/// refetch. Each response is cached the moment it arrives, so a failed run
/// resumes where it stopped.
class PubDevLicenceClient {
  /// Creates a client caching to `<cacheDir>/licence_check_cache.json`.
  ///
  /// One [http.Client] (keep-alive) serves every request of a run; pass
  /// [httpClient] to inject one in tests, otherwise a real one is created.
  /// Call [close] when the run is over. Transient failures are retried up
  /// to `maxAttempts` times with exponential backoff from `baseDelay` plus
  /// jitter ([random]), waiting through [delay] (injected in tests so they
  /// never sleep) and logging each retry through [log].
  PubDevLicenceClient({
    required String cacheDir,
    http.Client? httpClient,
    Future<void> Function(Duration)? delay,
    Random? random,
    void Function(String)? log,
    int maxAttempts = 5,
    Duration baseDelay = const Duration(milliseconds: 500),
  }) : _cacheFile = File(p.join(cacheDir, 'licence_check_cache.json')),
       _log = log ?? stderr.writeln,
       _http = RetryingHttp(
         service: 'pub.dev',
         httpClient: httpClient,
         delay: delay,
         random: random,
         log: log,
         maxAttempts: maxAttempts,
         baseDelay: baseDelay,
       );

  final File _cacheFile;
  final RetryingHttp _http;
  final void Function(String) _log;
  Map<String, dynamic>? _cache;

  /// Closes the underlying HTTP client, ending the keep-alive connection.
  void close() => _http.close();

  /// Returns `packageName` at `version`'s [PackageLicences] (the locked
  /// version; the latest's only as a logged fallback when pub.dev has not
  /// analysed that version), from the on-disk cache if
  /// present, else fetched from pub.dev and then cached. Throws
  /// [CommandFailure] on a non-200 response or an unparseable body.
  Future<PackageLicences> licencesFor(
    String packageName,
    String version,
  ) async {
    final cache = _loadCache();
    final key = '$packageName@$version';
    final cached = cache[key];
    if (cached is List) {
      return PackageLicences(cached.cast<String>());
    }

    var suffixes = await _fetchLicenceSuffixes(
      packageName,
      'https://pub.dev/api/packages/$packageName/versions/$version/score',
    );
    if (suffixes.isEmpty) {
      // pub.dev analyses a version lazily: an older locked version (or a
      // just-published one) can have no tags at all. Fall back to the
      // package-level (latest version) score, loudly, rather than denying a
      // package whose licence is perfectly well known.
      _log(
        'pub.dev has no licence tags for $packageName $version; '
        "falling back to the latest version's score",
      );
      suffixes = await _fetchLicenceSuffixes(
        packageName,
        'https://pub.dev/api/packages/$packageName/score',
      );
    }

    cache[key] = suffixes;
    _saveCache(cache);

    return PackageLicences(suffixes);
  }

  Future<List<String>> _fetchLicenceSuffixes(
    String packageName,
    String url,
  ) async {
    final uri = Uri.parse(url);
    final response = await _http.send(
      packageName,
      uri,
      (client) => client.get(uri),
    );

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (e) {
      throw CommandFailure('pub.dev response for $packageName: $e');
    }
    if (decoded is! Map || decoded['tags'] is! List) {
      throw CommandFailure(
        "pub.dev response for $packageName has no 'tags' list.",
      );
    }

    return (decoded['tags'] as List)
        .cast<String>()
        .where((t) => t.startsWith('license:'))
        .map((t) => t.substring('license:'.length))
        .toList();
  }

  Map<String, dynamic> _loadCache() {
    final loaded = _cache;
    if (loaded != null) return loaded;
    if (!_cacheFile.existsSync()) return _cache = <String, dynamic>{};
    try {
      final decoded = jsonDecode(_cacheFile.readAsStringSync());

      // Entries keyed by a bare package name are the old format (the
      // latest version's tags, not the locked one's): dropped, never reused.
      return _cache = decoded is Map
          ? (Map<String, dynamic>.from(decoded)
              ..removeWhere((key, _) => !key.contains('@')))
          : <String, dynamic>{};
    } on FormatException {
      // A corrupt cache file is never a hard failure — just refetch.
      return _cache = <String, dynamic>{};
    }
  }

  void _saveCache(Map<String, dynamic> cache) {
    _cache = cache;
    try {
      _cacheFile.parent.createSync(recursive: true);
      _cacheFile.writeAsStringSync(jsonEncode(cache));
    } on FileSystemException {
      // Caching is an optimisation, never load-bearing — a read-only or
      // missing .dart_tool/ must not fail the licence check itself.
    }
  }
}

/// The pub.dev score endpoint's `tags` array for one package, filtered to
/// the tags carrying a `license:` prefix — everything this class needs is
/// derived from that list. Returned by [PubDevLicenceClient.licencesFor].
class PackageLicences {
  /// Creates a result from the raw `license:`-prefixed tag suffixes (e.g.
  /// `['bsd-3-clause', 'fsf-libre', 'osi-approved']` — see this file's
  /// module doc for the endpoint shape).
  const PackageLicences(this.rawTagSuffixes);

  /// Every `license:<suffix>` tag's `<suffix>`, verbatim from the API
  /// response, badges (`fsf-libre`, `osi-approved`, `unknown`) included.
  final List<String> rawTagSuffixes;

  /// The tag suffixes with a known SPDX mapping in [pubDevTagToSpdx],
  /// translated to their canonical policy-document identifier. Multiple
  /// entries mean the package is dual/multi-licensed; [unrecognisedTags]
  /// carries anything with the `license:` prefix that isn't a badge
  /// (see [pubDevNonLicenceTags]) and isn't in [pubDevTagToSpdx] either.
  List<String> get spdxCandidates => rawTagSuffixes
      .where((t) => !pubDevNonLicenceTags.contains(t))
      .map((t) => pubDevTagToSpdx[t])
      .whereType<String>()
      .toList();

  /// `license:` tag suffixes that are neither a known badge nor a known
  /// SPDX mapping — never silently dropped; the licence-check command
  /// treats a package with only unrecognised tags (and no recognised
  /// candidate) as denied, listing them, rather than skipping it.
  List<String> get unrecognisedTags => rawTagSuffixes
      .where(
        (t) =>
            !pubDevNonLicenceTags.contains(t) &&
            !pubDevTagToSpdx.containsKey(t),
      )
      .toList();

  /// True if pub.dev reported no `license:` tag at all (as opposed to
  /// `license:unknown`, which does carry the prefix).
  bool get isEmpty => rawTagSuffixes.isEmpty;
}
