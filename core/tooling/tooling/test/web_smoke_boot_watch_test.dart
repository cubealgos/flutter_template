import 'package:test/test.dart';
import 'package:tooling/src/web_smoke_boot_watch.dart';

const int _httpOk = 200;
const int _httpNotFound = 404;

Map<String, dynamic> _exceptionEvent(String description) => {
  'method': 'Runtime.exceptionThrown',
  'params': {
    'exceptionDetails': {
      'text': 'Uncaught',
      'exception': {'description': description},
    },
  },
};

Map<String, dynamic> _consoleEvent(String type, List<String> texts) => {
  'method': 'Runtime.consoleAPICalled',
  'params': {
    'type': type,
    'args': [
      for (final t in texts) <String, dynamic>{'type': 'string', 'value': t},
    ],
  },
};

Map<String, dynamic> _logEvent(String level, String text) => {
  'method': 'Log.entryAdded',
  'params': {
    'entry': {'level': level, 'text': text},
  },
};

Map<String, dynamic> _responseEvent(String url, int status) => {
  'method': 'Network.responseReceived',
  'params': {
    'response': {'url': url, 'status': status},
  },
};

void main() {
  group('collectBootIssues: baseline', () {
    test('no events, no issues', () {
      expect(collectBootIssues(const []), isEmpty);
    });

    test('an unrelated event produces no issue', () {
      final events = [
        {'method': 'Page.frameStoppedLoading', 'params': <String, dynamic>{}},
      ];
      expect(collectBootIssues(events), isEmpty);
    });

    test('collects multiple issues across multiple events', () {
      final events = [
        _exceptionEvent('boom'),
        _consoleEvent('error', ['also boom']),
        _logEvent('error', 'and this too'),
      ];
      const expectedIssueCount = 3;
      expect(collectBootIssues(events), hasLength(expectedIssueCount));
    });
  });

  group('collectBootIssues: exceptions', () {
    test('reports the deferred-library exception', () {
      final events = [
        _exceptionEvent('Error: Deferred library l_de was not loaded.'),
      ];
      final issues = collectBootIssues(events);
      expect(issues, hasLength(1));
      expect(issues.single.kind, 'exception');
      expect(issues.single.description, contains('Deferred library l_de'));
    });
  });

  group('collectBootIssues: console', () {
    test('reports a console.error with its argument text', () {
      final events = [
        _consoleEvent('error', ['boom']),
      ];
      final issues = collectBootIssues(events);
      expect(issues, hasLength(1));
      expect(issues.single.kind, 'console-error');
      expect(issues.single.description, contains('boom'));
    });

    test('reports a console.assert', () {
      final events = [
        _consoleEvent('assert', ['assertion failed']),
      ];
      expect(collectBootIssues(events), hasLength(1));
    });

    test('does not report console.warn or console.log', () {
      final events = [
        _consoleEvent('warning', ['just fyi']),
        _consoleEvent('log', ['hello']),
      ];
      expect(collectBootIssues(events), isEmpty);
    });
  });

  group('collectBootIssues: log entries', () {
    test('reports an error-level Log.entryAdded', () {
      final events = [_logEvent('error', 'resource failed to load')];
      final issues = collectBootIssues(events);
      expect(issues, hasLength(1));
      expect(issues.single.kind, 'log-error');
    });

    test('does not report a warning-level Log.entryAdded', () {
      final events = [_logEvent('warning', 'heads up')];
      expect(collectBootIssues(events), isEmpty);
    });
  });

  group('hasSuccessfulResponse', () {
    test('finds a matching 200 response', () {
      final events = [
        _responseEvent('http://127.0.0.1:8080/motion.js', _httpOk),
      ];
      expect(hasSuccessfulResponse(events, 'motion.js'), isTrue);
    });

    test('ignores a non-200 response for the same URL', () {
      final events = [
        _responseEvent('http://127.0.0.1:8080/motion.js', _httpNotFound),
      ];
      expect(hasSuccessfulResponse(events, 'motion.js'), isFalse);
    });

    test('ignores a 200 response for an unrelated URL', () {
      final events = [
        _responseEvent('http://127.0.0.1:8080/site.css', _httpOk),
      ];
      expect(hasSuccessfulResponse(events, 'motion.js'), isFalse);
    });

    test('no events, no match', () {
      expect(hasSuccessfulResponse(const [], 'motion.js'), isFalse);
    });
  });
}
