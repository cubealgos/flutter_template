import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/web_smoke_axe.dart';
import 'package:tooling/src/web_smoke_boot_watch.dart';
import 'package:tooling/src/web_smoke_cdp_session.dart';
import 'package:tooling/src/web_smoke_chrome_path.dart';
import 'package:tooling/src/web_smoke_chrome_process.dart';
import 'package:tooling/src/web_smoke_i18n.dart';
import 'package:tooling/src/web_smoke_options.dart';
import 'package:tooling/src/web_smoke_static_server.dart';

/// How long a boot is observed for an exception/console error before the
/// DOM is even checked — "during boot + ~5s" from the issue's acceptance
/// criteria. Uncaught JS exceptions surface as a
/// `Runtime.exceptionThrown` event any time in this window, not only at
/// the instant of navigation.
const Duration webSmokeObserveWindow = Duration(seconds: 5);

/// Extra time [WebSmokeCommand] keeps polling the DOM after
/// [webSmokeObserveWindow] elapses, for a boot that's merely slow (a cold
/// CI runner) rather than broken — polling stops as soon as a check
/// passes.
const Duration webSmokeDomGrace = Duration(seconds: 5);

/// Interval between DOM re-checks during [webSmokeDomGrace].
const Duration webSmokeDomPollInterval = Duration(milliseconds: 250);

/// A DOM/network assertion run against a booted page. Returns the list of
/// problems found (empty = passed). Takes the live [CdpPageSession] so it
/// can both evaluate JS and inspect events already captured on it
/// (`hasSuccessfulResponse`) — see `_appDomCheck`/`_websiteDomCheck`.
typedef _DomCheck = Future<List<String>> Function(CdpPageSession session);

/// `web_smoke`: boots `apps/app`'s and `apps/website`'s built web output
/// in a real headless Chromium over the DevTools Protocol and fails if
/// either never gets past its splash, throws an uncaught exception, or
/// logs a console error — a class of regression found only by
/// opening the app in Chrome by hand (a deferred-library exception on the
/// `de` locale, and a web splash that outlived the app underneath it)
/// while every other CI check stayed green.
///
/// Requires both `apps/app/build/web` (`flutter build web
/// --dart-define=BACKEND=fake`) and `apps/website/build/jaspr` (`melos
/// run website:build`) to already exist — see the `web-smoke` melos
/// script, which builds both first. Usage: `fvm dart run tooling:web_smoke`
/// (also wired as `melos run web-smoke`).
class WebSmokeCommand {
  /// Creates the command. [out]/[err] default to stdout/stderr; tests
  /// override them to capture output instead of printing it.
  WebSmokeCommand({this.out = _defaultOut, this.err = _defaultErr});

  /// Sink for normal progress messages.
  final void Function(String) out;

  /// Sink for error messages.
  final void Function(String) err;

  static void _defaultOut(String message) => stdout.writeln(message);
  static void _defaultErr(String message) => stderr.writeln(message);

  /// Runs the command against the repository rooted at [repoRoot]. Returns
  /// the process exit code.
  Future<int> run(List<String> args, {required String repoRoot}) =>
      runCatchingFailures(() => _run(args, repoRoot), err);

  Future<void> _run(List<String> args, String repoRoot) async {
    final options = parseWebSmokeArgs(args);
    final chrome = resolveChromeExecutable(
      flagValue: options.chrome,
      environment: Platform.environment,
      isMacOS: Platform.isMacOS,
    );
    out('web-smoke: using Chromium executable "$chrome".');

    final failures = <String>[];
    if (options.only == null || options.only == 'app') {
      failures.addAll(await _smokeApp(repoRoot, chrome));
    }
    if (options.only == null || options.only == 'website') {
      failures.addAll(await _smokeWebsite(repoRoot, chrome));
    }

    if (failures.isNotEmpty) {
      throw CommandFailure(
        'web-smoke found ${failures.length} problem(s):\n\n'
        '${failures.join('\n\n')}',
      );
    }
    out('web-smoke: every target booted cleanly.');
  }

  Future<List<String>> _smokeApp(String repoRoot, String chrome) async {
    final appDir = p.join(repoRoot, 'apps', 'app', 'build', 'web');
    _requireBuilt(appDir, 'apps/app/build/web', 'web-smoke:build-app');

    final axeSource = loadAxeSource(repoRoot);
    final server = await WebSmokeStaticServer.start(appDir);
    final failures = <String>[];
    try {
      for (final locale in _appLocales(repoRoot)) {
        out('web-smoke: booting apps/app (${locale.lang})...');
        final target = _PageSmokeTarget(
          navigatePath: '/',
          lang: locale.lang,
          domCheck: _appDomCheck(locale.expectedText),
          axeSource: axeSource,
        );
        final problems = await _smokeOnePage(chrome, server.baseUrl, target);
        _report(failures, 'apps/app (${locale.lang})', problems);
      }
    } finally {
      await server.close();
    }

    return failures;
  }

  Future<List<String>> _smokeWebsite(String repoRoot, String chrome) async {
    final siteDir = p.join(repoRoot, 'apps', 'website', 'build', 'jaspr');
    _requireBuilt(siteDir, 'apps/website/build/jaspr', 'website:build');

    final server = await WebSmokeStaticServer.start(siteDir);
    final failures = <String>[];
    try {
      for (final route in _websiteRoutes) {
        out('web-smoke: booting apps/website (${route.path})...');
        final target = _PageSmokeTarget(
          navigatePath: route.path,
          lang: 'en-US',
          domCheck: _websiteDomCheck(route.expectedLang),
        );
        final problems = await _smokeOnePage(chrome, server.baseUrl, target);
        _report(failures, 'apps/website (${route.path})', problems);
      }
    } finally {
      await server.close();
    }

    return failures;
  }

  void _report(List<String> failures, String label, List<String> problems) {
    if (problems.isEmpty) {
      out('web-smoke: $label OK.');

      return;
    }
    failures.add('$label:\n  - ${problems.join('\n  - ')}');
  }

  void _requireBuilt(String dir, String relativeLabel, String buildScript) {
    final indexFile = File(p.join(dir, 'index.html'));
    if (!indexFile.existsSync()) {
      throw CommandFailure(
        '$relativeLabel not found — run `dart run melos run $buildScript` '
        'first (or just `dart run melos run web-smoke`, which builds '
        'both).',
      );
    }
  }

  List<_LocaleExpectation> _appLocales(String repoRoot) {
    final i18nDir = p.join(repoRoot, 'apps', 'app', 'lib', 'i18n');
    final en = _signInTitle(i18nDir, 'en.i18n.json');
    final de = _signInTitle(i18nDir, 'de.i18n.json');

    return [
      _LocaleExpectation(lang: 'en-US', expectedText: en),
      _LocaleExpectation(lang: 'de-DE', expectedText: de),
    ];
  }

  String _signInTitle(String i18nDir, String fileName) {
    final content = File(p.join(i18nDir, fileName)).readAsStringSync();

    return readI18nString(content, const ['signIn', 'title']);
  }
}

const List<_RouteExpectation> _websiteRoutes = [
  _RouteExpectation(path: '/', expectedLang: 'en'),
  _RouteExpectation(path: '/de/', expectedLang: 'de'),
];

/// One locale [WebSmokeCommand] boots `apps/app` under: the `--lang`/
/// `Accept-Language`/`navigator.language` value to force, and the
/// localized sign-in title expected to render once booted.
class _LocaleExpectation {
  const _LocaleExpectation({required this.lang, required this.expectedText});

  final String lang;
  final String expectedText;
}

/// One `apps/website` route [WebSmokeCommand] boots: its path and the
/// `<html lang>` value expected on it.
class _RouteExpectation {
  const _RouteExpectation({required this.path, required this.expectedLang});

  final String path;
  final String expectedLang;
}

/// One page [_smokeOnePage] boots: the path to navigate to, the locale to
/// force, and the assertion to run once it's settled. Bundled into one
/// object rather than three more parameters on [_smokeOnePage] itself —
/// solid_lints caps a function at four parameters (see root
/// `analysis_options.yaml`'s `number_of_parameters`).
class _PageSmokeTarget {
  const _PageSmokeTarget({
    required this.navigatePath,
    required this.lang,
    required this.domCheck,
    this.axeSource,
  });

  final String navigatePath;
  final String lang;
  final _DomCheck domCheck;

  /// The axe-core source to inject and run once the DOM check passes, or
  /// `null` to skip axe (the website isn't checked by it).
  final String? axeSource;
}

Future<List<String>> _smokeOnePage(
  String chrome,
  String httpBaseUrl,
  _PageSmokeTarget target,
) async {
  final userDataDir = Directory.systemTemp.createTempSync('web_smoke_');
  ChromeProcess? chromeProcess;
  CdpPageSession? session;
  try {
    chromeProcess = await ChromeProcess.launch(
      executable: chrome,
      lang: target.lang,
      userDataDir: userDataDir,
    );
    session = await CdpPageSession.connectToFirstPage(chromeProcess.httpBase);
    await _armSession(session, target.lang);
    await session.send('Page.navigate', {
      'url': '$httpBaseUrl${target.navigatePath}',
    });
    await Future<void>.delayed(webSmokeObserveWindow);

    final domProblems = await _pollDomCheck(session, target.domCheck);
    final bootIssues = collectBootIssues(session.eventsSoFar());
    final axeSource = target.axeSource;
    // axe reads the semantics DOM, which only exists once the DOM check
    // passed; running it on a broken boot would just add noise.
    final axeFindings = axeSource == null || domProblems.isNotEmpty
        ? const <String>[]
        : await _runAxe(session, axeSource);

    return [
      ...bootIssues.map((issue) => issue.toString()),
      ...domProblems,
      ...axeFindings,
    ];
  } finally {
    await session?.close();
    await chromeProcess?.close();
    await deleteTempDirBestEffort(userDataDir);
  }
}

/// Injects [axeSource] into the booted page and returns one problem per
/// serious or critical axe violation (see [axeProblems]).
Future<List<String>> _runAxe(CdpPageSession session, String axeSource) async {
  await session.send('Runtime.evaluate', {'expression': axeSource});
  final response = await session.send('Runtime.evaluate', {
    'expression': axeRunExpression,
    'awaitPromise': true,
    'returnByValue': true,
  });
  final result = response['result'];
  final inner = result is Map ? result['result'] : null;
  final value = inner is Map ? inner['value'] : null;
  if (value is! String) {
    throw CommandFailure('axe.run returned no JSON string: $response');
  }

  return axeProblems(value);
}

/// Deletes [dir], a throwaway Chrome profile, without ever failing the
/// smoke run over it.
///
/// Chrome's helper processes (renderer, crashpad) can outlive the main
/// process that `ChromeProcess.close` waits for and keep writing into the
/// profile for a moment, so a single `deleteSync` intermittently fails with
/// "Directory not empty" (seen in CI). Retries a few times, then
/// leaves the directory for the OS temp cleanup with a warning on stderr —
/// a leftover temp dir says nothing about whether the page booted.
///
/// [delete] defaults to a recursive `deleteSync`; tests inject a failing one.
Future<void> deleteTempDirBestEffort(
  Directory dir, {
  int attempts = 5,
  Duration pause = const Duration(milliseconds: 200),
  void Function(Directory dir) delete = _deleteRecursively,
}) async {
  for (var attempt = 1; attempt <= attempts; attempt++) {
    if (!dir.existsSync()) return;
    try {
      delete(dir);

      return;
    } on FileSystemException catch (error) {
      if (attempt == attempts) {
        stderr.writeln(
          'web-smoke: warning: could not delete ${dir.path} '
          '(${error.osError?.message ?? error.message}); leaving it.',
        );

        return;
      }
      await Future<void>.delayed(pause);
    }
  }
}

/// Enables the CDP domains this whole tool needs and forces [lang] onto
/// every locale-detection surface a page can read. Three separate calls
/// because each covers a different surface, confirmed by hand (see the
/// issue's write-up): `Emulation.setLocaleOverride` only affects `Intl.*`
/// formatting, plain `--lang`/`Network.setExtraHTTPHeaders` only affects
/// the `Accept-Language` HTTP header, and neither moves
/// `navigator.language` — only `Emulation.setUserAgentOverride`'s
/// `acceptLanguage` does, which is what `LocaleSettings.useDeviceLocaleSync`
/// (`apps/app/lib/main.dart`) actually reads on web.
Future<void> _armSession(CdpPageSession session, String lang) async {
  await session.send('Page.enable');
  await session.send('Runtime.enable');
  await session.send('Log.enable');
  await session.send('Network.enable');
  await session.send('Network.setExtraHTTPHeaders', {
    'headers': {'Accept-Language': lang},
  });
  await session.send('Emulation.setLocaleOverride', {'locale': lang});

  final version = await session.send('Browser.getVersion');
  final userAgent = (version['result'] as Map)['userAgent'] as String;
  await session.send('Emulation.setUserAgentOverride', {
    'userAgent': userAgent,
    'acceptLanguage': lang,
  });
}

Future<List<String>> _pollDomCheck(
  CdpPageSession session,
  _DomCheck domCheck,
) async {
  final deadline = DateTime.now().add(webSmokeDomGrace);
  var problems = await domCheck(session);
  while (problems.isNotEmpty && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(webSmokeDomPollInterval);
    problems = await domCheck(session);
  }

  return problems;
}

_DomCheck _appDomCheck(String expectedText) {
  return (session) async {
    final response = await session.send('Runtime.evaluate', {
      'expression': _appCheckExpression(expectedText),
      'returnByValue': true,
    });
    final state = _decodeEvalString(response);
    final problems = <String>[];
    if (state['splashGone'] != true) {
      problems.add('the web splash (#splash) is still in the DOM');
    }
    if (state['flutterRendered'] != true) {
      problems.add('no flt-glass-pane/flutter-view found in the DOM');
    }
    if (state['semanticsPresent'] != true) {
      problems.add(
        'no flt-semantics in the DOM: web semantics are not enabled at '
        'start-up',
      );
    }
    if (state['textPresent'] != true) {
      problems.add('localized text "$expectedText" not found in the DOM');
    }

    return problems;
  };
}

/// Reads the booted page's state. It does NOT click Flutter web's hidden
/// `flt-semantics-placeholder`: `apps/app`'s `main()` enables semantics at
/// start-up, so the text-bearing `flt-semantics` DOM must already
/// exist, and `semanticsPresent` asserts exactly that.
String _appCheckExpression(String expectedText) {
  final encodedText = jsonEncode(expectedText);

  return '''
(() => {
  const splashGone = document.getElementById('splash') === null;
  const flutterRendered = !!(
    document.querySelector('flt-glass-pane') ||
    document.querySelector('flutter-view')
  );
  const text = document.body.innerText || '';
  return JSON.stringify({
    splashGone: splashGone,
    flutterRendered: flutterRendered,
    textPresent: text.indexOf($encodedText) !== -1,
    semanticsPresent: document.querySelector('flt-semantics') !== null,
  });
})()
''';
}

_DomCheck _websiteDomCheck(String expectedLang) {
  return (session) async {
    final response = await session.send('Runtime.evaluate', {
      'expression': 'JSON.stringify({lang: document.documentElement.lang})',
      'returnByValue': true,
    });
    final state = _decodeEvalString(response);
    final problems = <String>[];
    if (state['lang'] != expectedLang) {
      problems.add(
        '<html lang> is "${state['lang']}", expected "$expectedLang"',
      );
    }
    if (!hasSuccessfulResponse(session.eventsSoFar(), 'motion.js')) {
      problems.add('motion.js never loaded (no 200 response observed)');
    }

    return problems;
  };
}

Map<String, dynamic> _decodeEvalString(Map<String, dynamic> response) {
  final result = response['result'];
  final inner = result is Map ? result['result'] : null;
  final value = inner is Map ? inner['value'] : null;
  if (value is! String) {
    throw CommandFailure(
      'Runtime.evaluate returned no string value: '
      '$response',
    );
  }

  return jsonDecode(value) as Map<String, dynamic>;
}

void _deleteRecursively(Directory dir) => dir.deleteSync(recursive: true);
