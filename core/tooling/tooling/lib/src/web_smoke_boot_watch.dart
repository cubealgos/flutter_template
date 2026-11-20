/// One problem found in a boot-smoke observation window: an uncaught JS
/// exception, a console `error`, or an `error`-level browser log entry —
/// the three surfaces that two earlier bugs (the deferred-library exception,
/// the leftover web splash) would have shown up on if anything had been
/// watching. [kind] is one of `exception`, `console-error` or `log-error`;
/// [description] is a human-readable summary suitable for printing
/// straight into a failure message.
//
// This file is named for what it does (`collectBootIssues`), not for
// this small value class — the file's first declared type.
// ignore: solid_lints/prefer_match_file_name
class BootIssue {
  /// Creates an issue.
  const BootIssue(this.kind, this.description);

  /// Which CDP surface reported this issue.
  final String kind;

  /// A human-readable summary of the issue.
  final String description;

  @override
  String toString() => '[$kind] $description';
}

/// Scans [events] — raw CDP protocol messages, `{"method": ..., "params":
/// ...}` maps, exactly the shape `CdpPageSession.eventsSoFar()` returns —
/// and returns every [BootIssue] found.
///
/// Pure: [events] is plain decoded JSON, not a live CDP connection, so a
/// test can fabricate an event stream by hand instead of driving a real
/// browser — see `web_smoke_boot_watch_test.dart`. The live capture (an
/// `Runtime.enable`/`Log.enable`'d `CdpPageSession` accumulating events
/// during the observation window) lives in `web_smoke_cdp_session.dart`.
List<BootIssue> collectBootIssues(Iterable<Map<String, dynamic>> events) {
  final issues = <BootIssue>[];
  for (final event in events) {
    final issue = _issueForEvent(event);
    if (issue != null) issues.add(issue);
  }

  return issues;
}

BootIssue? _issueForEvent(Map<String, dynamic> event) {
  final method = event['method'];
  final params = _paramsOf(event);
  switch (method) {
    case 'Runtime.exceptionThrown':
      return BootIssue('exception', _exceptionText(params));
    case 'Runtime.consoleAPICalled':
      return _consoleIssue(params);
    case 'Log.entryAdded':
      return _logIssue(params);
    default:
      return null;
  }
}

Map<String, dynamic> _paramsOf(Map<String, dynamic> event) {
  final params = event['params'];

  return params is Map ? params.cast<String, dynamic>() : const {};
}

String _exceptionText(Map<String, dynamic> params) {
  final details = params['exceptionDetails'];
  if (details is! Map) return 'Runtime.exceptionThrown (no details)';

  final exception = details['exception'];
  final description = exception is Map ? exception['description'] : null;

  return (description ?? details['text'] ?? 'unknown exception').toString();
}

BootIssue? _consoleIssue(Map<String, dynamic> params) {
  final type = params['type'];
  if (type != 'error' && type != 'assert') return null;

  final args = params['args'];
  final text = args is List
      ? args.map(_consoleArgText).where((s) => s.isNotEmpty).join(' ')
      : '';

  return BootIssue(
    'console-error',
    text.isEmpty ? 'console.$type() with no arguments' : text,
  );
}

String _consoleArgText(dynamic arg) {
  if (arg is! Map) return '';

  return (arg['description'] ?? arg['value'] ?? '').toString();
}

BootIssue? _logIssue(Map<String, dynamic> params) {
  final entry = params['entry'];
  if (entry is! Map || entry['level'] != 'error') return null;
  final text = entry['text'] ?? 'unknown log entry';

  return BootIssue('log-error', text.toString());
}

/// Whether [events] contains a `Network.responseReceived` event for a URL
/// ending in [urlSuffix] with HTTP status 200 — used to assert a resource
/// (e.g. `apps/website`'s `motion.js`) actually loaded, not just that a
/// `<script>` tag referencing it exists in the DOM. Pure, for the same
/// reason as [collectBootIssues].
bool hasSuccessfulResponse(
  Iterable<Map<String, dynamic>> events,
  String urlSuffix,
) {
  for (final event in events) {
    if (event['method'] != 'Network.responseReceived') continue;
    final params = _paramsOf(event);
    final response = params['response'];
    if (response is! Map) continue;
    final url = response['url'];
    final status = response['status'];
    if (url is String && url.endsWith(urlSuffix) && status == _httpOk) {
      return true;
    }
  }

  return false;
}

/// The HTTP status [hasSuccessfulResponse] treats as "loaded".
const int _httpOk = 200;
