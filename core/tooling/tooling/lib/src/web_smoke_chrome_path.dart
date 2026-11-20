/// Resolves the Chromium/Chrome executable `WebSmokeCommand` launches:
/// [flagValue] (the `--chrome` flag) wins when given, then [environment]'s
/// `CHROME` variable, then a platform default.
///
/// The platform default differs on purpose: on a developer's Mac there is
/// no `chromium`/`google-chrome` on `PATH` in general, but Google Chrome is
/// near-universally installed as an application bundle at a fixed path —
/// so [isMacOS] picks that absolute path. CI (`.github/workflows/web-smoke.yml`)
/// runs Debian and downloads a pinned Chrome for Testing build (exact
/// version + sha256, from the official `chrome-for-testing-public` GCS
/// bucket — see that file's own comment for why not Debian's `chromium`
/// apt package) into the runner's tool cache, and sets the `CHROME` env var
/// to it, so this flows through the *second* branch below rather than the
/// platform default; the bare `chromium` fallback here only matters for a Linux
/// dev machine with no `CHROME` set. Pure (no filesystem or process
/// access), so it's exercised directly by `web_smoke_chrome_path_test.dart`
/// without touching a real browser.
String resolveChromeExecutable({
  required String? flagValue,
  required Map<String, String> environment,
  required bool isMacOS,
}) {
  if (flagValue != null && flagValue.isNotEmpty) return flagValue;

  final envValue = environment['CHROME'];
  if (envValue != null && envValue.isNotEmpty) return envValue;

  return isMacOS
      ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
      : 'chromium';
}
