import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/linux_cmake_ids.dart';
import 'package:tooling/src/linux_desktop_entry.dart';
import 'package:tooling/src/package_rename_config_yaml.dart';
import 'package:tooling/src/process_runner.dart';
import 'package:tooling/src/rename_identity.dart';
import 'package:tooling/src/rename_leftover_check.dart';
import 'package:tooling/src/rename_text_rewrite.dart';
import 'package:yaml/yaml.dart';

/// See `icons_command.dart`'s identical constant for the full rationale —
/// suppresses Dart/Flutter tooling telemetry for every subprocess below.
const String _suppressAnalyticsEnvVar = 'DASH__SUPPRESS_ANALYTICS';
const Map<String, String> _renameEnvironment = {
  _suppressAnalyticsEnvVar: 'true',
};

/// The melos scripts `rename` runs, in order, once every file is rewritten:
/// `gen` regenerates every generated file the rewrite touched (the `appTitle`
/// i18n placeholder → `strings_*.g.dart`), `map` regenerates
/// `docs/map.md`/`docs/map/*.md` (sourced from each pubspec's `description:`,
/// also rewritten), and `analyze` is the cheapest whole-workspace proof the
/// result still resolves (a missed `package:<old>/` import fails here).
/// Deliberately not part of `verification_suite.dart`'s
/// `verificationMelosScripts` — that list is `finish`'s own, larger,
/// slower-on-purpose check suite; `rename` needs its own, narrower one.
const List<String> postRenameMelosScripts = <String>['gen', 'map', 'analyze'];

const String _usage =
    'Usage: rename --name <snake_case> --org <reverse.domain> '
    '--display "<Display Name>" [--app-package <snake_case>]';

/// `rename`: renames the whole cloned template so a new app starts clean —
/// see CLAUDE.md's "start a new app from this template" row.
///
/// Runs package_rename (BSD-3-Clause, pub.dev/packages/package_rename;
/// added as `apps/app`'s own dev_dependency, same pattern as
/// flutter_launcher_icons/flutter_native_splash — see that pubspec.yaml)
/// for the native fields package_rename's own schema covers (Android
/// `applicationId`/`namespace`/Kotlin package directory/`android:label`;
/// iOS `PRODUCT_BUNDLE_IDENTIFIER`/`CFBundleDisplayName`/`CFBundleName`;
/// macOS `PRODUCT_BUNDLE_IDENTIFIER`/product name; Linux
/// `APPLICATION_ID`/`BINARY_NAME`/window title; Windows
/// `BINARY_NAME`/`Runner.rc`/window title; web `<title>`,
/// `apple-mobile-web-app-title`, `manifest.json` `name`/`short_name`), then
/// this command fills the one native gap package_rename's own source
/// doesn't cover — `linux/app.desktop` (added after package_rename
/// 1.10.1 was written) — and rewrites every Dart-level surface itself:
/// pubspec names/descriptions, `package:<old>/` imports, `README.md`/
/// `CLAUDE.md`/`apps/app/README.md` mentions, the root governance/legal
/// files' body text (`NOTICE`/`CLA.md`/`CONTRIBUTING.md`/`SECURITY.md`,
/// their legal-identity placeholders left alone, see the root
/// README's "After cloning" checklist) and the `appTitle` i18n
/// placeholder.
///
/// `--app-package` defaults to unset, keeping `apps/app`'s Dart package
/// name as `app`: this is a clone-per-app template (CLAUDE.md's opening
/// line — "each app clones this repo and then owns its copy outright"),
/// never a multi-app monorepo, so nothing else in the workspace needs the
/// app package to have a globally-unique name. Pass `--app-package` only if
/// a clone has its own reason to rename it.
class RenameCommand {
  /// Creates the command. [out]/[err] default to stdout/stderr; tests
  /// override them to capture output instead of printing it.
  RenameCommand({
    required this.runner,
    this.out = _defaultOut,
    this.err = _defaultErr,
  });

  /// The process runner `git`/`fvm` are invoked through.
  final ProcessRunner runner;

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
    final request = _parseArgs(args);
    await _refuseIfDirty(repoRoot);
    final old = _readOldIdentity(repoRoot);

    await _runPackageRename(repoRoot, request, old);
    _regenerateLinuxDesktopEntry(repoRoot, request.display);
    _rewriteWorkspacePubspecs(repoRoot, request, old);
    _rewriteProseMentions(repoRoot, old.templateToken, request.name);
    _rewriteI18nAppTitle(repoRoot, request.display);
    _rewriteWebsiteIdentity(repoRoot, request.display);
    final appPackage = request.appPackage;
    if (appPackage != null && appPackage != old.appPackageName) {
      _renameAppPackage(repoRoot, old.appPackageName, appPackage);
    }

    await _pubGet(repoRoot);
    for (final script in postRenameMelosScripts) {
      await _runMelosScript(repoRoot, script);
    }

    _checkNoLeftovers(repoRoot, old);
    out(
      'rename: done. ${request.name} (${request.applicationId}, '
      '"${request.display}") replaces the flutter_template placeholder.',
    );
  }

  RenameRequest _parseArgs(List<String> args) {
    const knownFlags = {'--name', '--org', '--display', '--app-package'};
    // Every flag is `--flag value` — one flag token plus its value token.
    const flagWidth = 2;
    final values = <String, String>{};
    var i = 0;
    while (i < args.length) {
      final flag = args[i];
      if (!knownFlags.contains(flag)) {
        throw CommandFailure(
          'Unknown flag "$flag". $_usage',
          exitCode: usageExitCode,
        );
      }
      if (i + 1 >= args.length) {
        throw CommandFailure(
          '$flag requires a value. $_usage',
          exitCode: usageExitCode,
        );
      }
      values[flag] = args[i + 1];
      i += flagWidth;
    }

    final name = values['--name'];
    final org = values['--org'];
    final display = values['--display'];
    if (name == null || org == null || display == null) {
      throw CommandFailure(_usage, exitCode: usageExitCode);
    }

    return _validateRequest(
      name: name,
      org: org,
      display: display,
      appPackage: values['--app-package'],
    );
  }

  RenameRequest _validateRequest({
    required String name,
    required String org,
    required String display,
    required String? appPackage,
  }) {
    if (!isValidSnakeCaseName(name)) {
      throw CommandFailure(
        '--name must be lowercase snake_case (e.g. "acme_notes"), got '
        '"$name".',
      );
    }
    if (!isValidReverseDomainOrg(org)) {
      throw CommandFailure(
        '--org must be a reverse-domain identifier (e.g. "de.example"), got '
        '"$org".',
      );
    }
    if (display.trim().isEmpty) {
      throw CommandFailure('--display must not be empty.');
    }
    if (appPackage != null && !isValidSnakeCaseName(appPackage)) {
      throw CommandFailure(
        '--app-package must be lowercase snake_case, got "$appPackage".',
      );
    }

    return RenameRequest(
      name: name,
      org: org,
      display: display,
      appPackage: appPackage,
    );
  }

  Future<void> _refuseIfDirty(String repoRoot) async {
    final result = await runner.run('git', [
      'status',
      '--porcelain',
    ], workingDirectory: repoRoot);
    if (result.exitCode != 0) {
      throw CommandFailure('git status --porcelain failed: ${result.stderr}');
    }
    final dirty = (result.stdout as String).trim();
    if (dirty.isNotEmpty) {
      throw CommandFailure(
        'Working tree is dirty — rename produces one reviewable diff and '
        'refuses to run on top of uncommitted changes:\n$dirty',
      );
    }
  }

  OldIdentity _readOldIdentity(String repoRoot) {
    final appDir = p.join(repoRoot, 'apps', 'app');
    final applicationId = _readAndroidApplicationId(appDir);

    return OldIdentity(
      workspaceName: _readPubspecName(p.join(repoRoot, 'pubspec.yaml')),
      appPackageName: _readPubspecName(p.join(appDir, 'pubspec.yaml')),
      applicationId: applicationId,
      displayName: _readI18nAppTitle(appDir) ?? applicationId,
      macCopyright: _readXcconfigValue(
        p.join(appDir, 'macos', 'Runner', 'Configs', 'AppInfo.xcconfig'),
        'PRODUCT_COPYRIGHT',
      ),
      windowsCopyright: _readRunnerRcValue(
        p.join(appDir, 'windows', 'runner', 'Runner.rc'),
        'LegalCopyright',
      ),
    );
  }

  String _readPubspecName(String path) {
    final file = File(path);
    if (!file.existsSync()) throw CommandFailure('$path not found.');
    final doc = loadYaml(file.readAsStringSync());
    final name = doc is YamlMap ? doc['name'] as String? : null;
    if (name == null) throw CommandFailure('$path has no "name:".');

    return name;
  }

  String _readAndroidApplicationId(String appDir) {
    final file = File(p.join(appDir, 'android', 'app', 'build.gradle.kts'));
    if (!file.existsSync()) throw CommandFailure('${file.path} not found.');
    final match = RegExp(r'applicationId\s*=\s*"([^"]+)"')
        .firstMatch(file.readAsStringSync());
    if (match == null) {
      throw CommandFailure('${file.path}: no applicationId found.');
    }

    // The regex above only matches with a non-empty capture group.
    // ignore: solid_lints/avoid_non_null_assertion
    return match.group(1)!;
  }

  String? _readI18nAppTitle(String appDir) {
    final file = File(p.join(appDir, 'lib', 'i18n', 'en.i18n.json'));
    if (!file.existsSync()) return null;

    return RegExp(r'"appTitle":\s*"(.*?)"')
        .firstMatch(file.readAsStringSync())
        ?.group(1);
  }

  /// Reads an `.xcconfig` line shaped `KEY = value` (unquoted, to end of
  /// line — matches `AppInfo.xcconfig`'s own `PRODUCT_NAME`/
  /// `PRODUCT_BUNDLE_IDENTIFIER`/`PRODUCT_COPYRIGHT` lines).
  String _readXcconfigValue(String path, String key) {
    final file = File(path);
    if (!file.existsSync()) throw CommandFailure('$path not found.');
    final pattern = RegExp('^${RegExp.escape(key)} = (.*)\$', multiLine: true);
    final match = pattern.firstMatch(file.readAsStringSync());
    if (match == null) throw CommandFailure('$path: no "$key" value found.');

    // The regex above only matches with a non-empty capture group.
    // ignore: solid_lints/avoid_non_null_assertion
    return match.group(1)!.trim();
  }

  /// Reads a Windows `.rc` `VALUE "KEY", "value" "\0"` line — matches
  /// `Runner.rc`'s own `VALUE "..."` block, same shape
  /// package_rename's own `windows.dart` regexes target.
  String _readRunnerRcValue(String path, String key) {
    final file = File(path);
    if (!file.existsSync()) throw CommandFailure('$path not found.');
    final pattern = RegExp('VALUE "${RegExp.escape(key)}", "(.*?)" "\\\\0"');
    final match = pattern.firstMatch(file.readAsStringSync());
    if (match == null) throw CommandFailure('$path: no "$key" value found.');

    // The regex above only matches with a non-empty capture group.
    // ignore: solid_lints/avoid_non_null_assertion
    return match.group(1)!.trim();
  }

  // Building the config a subprocess consumes necessarily reads more of
  // [old] (the previous identity every field is derived from) than of this
  // command's own fields — moving it onto `OldIdentity` would leave that
  // pure, filesystem-free class needing to know about
  // `PackageRenameFields`/`RenameRequest` instead, the wrong direction.
  // ignore: solid_lints/feature_envy
  Future<void> _runPackageRename(
    String repoRoot,
    RenameRequest request,
    OldIdentity old,
  ) async {
    final appDir = p.join(repoRoot, 'apps', 'app');
    final lang =
        Directory(p.join(appDir, 'android', 'app', 'src', 'main', 'kotlin'))
            .existsSync()
        ? 'kotlin'
        : 'java';
    final fields = PackageRenameFields(
      displayName: request.display,
      applicationId: request.applicationId,
      exeName: request.name,
      organization: request.org,
      oldApplicationId: old.applicationId,
      androidLang: lang,
      macCopyright: old.rewriteCopyright(old.macCopyright, request.org),
      windowsCopyright: old.rewriteCopyright(old.windowsCopyright, request.org),
    );
    final configFile = File(p.join(appDir, 'package_rename_config.yaml'))
      ..writeAsStringSync(buildPackageRenameConfigYaml(fields));
    try {
      final result = await runner.run(
        'fvm',
        ['dart', 'run', 'package_rename', '--path=package_rename_config.yaml'],
        workingDirectory: appDir,
        environment: _renameEnvironment,
      );
      if (result.exitCode != 0) {
        throw CommandFailure(
          'package_rename failed:\n${result.stdout}\n${result.stderr}',
        );
      }
      out(
        'Ran package_rename for the native Android/iOS/macOS/Linux/Windows '
        'and web fields.',
      );
    } finally {
      if (configFile.existsSync()) configFile.deleteSync();
    }
  }

  void _regenerateLinuxDesktopEntry(String repoRoot, String display) {
    final appDir = p.join(repoRoot, 'apps', 'app');
    final cmakeFile = File(p.join(appDir, 'linux', 'CMakeLists.txt'));
    final LinuxCmakeIds ids;
    try {
      ids = readLinuxCmakeIds(cmakeFile.readAsStringSync());
    } on FormatException catch (e) {
      throw CommandFailure('${cmakeFile.path}: $e');
    }
    final entry = buildLinuxDesktopEntry(
      name: display,
      execName: ids.binaryName,
      iconId: ids.applicationId,
    );
    File(p.join(appDir, 'linux', 'app.desktop')).writeAsStringSync(entry);
    out(
      "Regenerated linux/app.desktop from CMakeLists.txt's (now renamed) "
      'ids — package_rename does not cover it (added after '
      "package_rename 1.10.1's release).",
    );
  }

  void _rewriteWorkspacePubspecs(
    String repoRoot,
    RenameRequest request,
    OldIdentity old,
  ) {
    final rootPubspecFile = File(p.join(repoRoot, 'pubspec.yaml'));
    rootPubspecFile.writeAsStringSync(
      replaceTemplateToken(
        rootPubspecFile.readAsStringSync(),
        oldToken: old.templateToken,
        newToken: request.name,
      ),
    );
    out(
      'Renamed the workspace root pubspec "name:" to '
      '${request.workspaceName}.',
    );

    for (final memberDir in _workspaceMemberDirs(repoRoot)) {
      final pubspecFile = File(p.join(repoRoot, memberDir, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) continue;
      final content = pubspecFile.readAsStringSync();
      final rewritten = replaceTemplateToken(
        content,
        oldToken: old.templateToken,
        newToken: request.name,
      );
      if (rewritten != content) pubspecFile.writeAsStringSync(rewritten);
    }
  }

  List<String> _workspaceMemberDirs(String repoRoot) {
    final doc = loadYaml(
      File(p.join(repoRoot, 'pubspec.yaml')).readAsStringSync(),
    );
    final list = doc is YamlMap ? doc['workspace'] : null;
    if (list is! YamlList) return const <String>[];

    return list.map((dynamic e) => e.toString()).toList();
  }

  void _rewriteProseMentions(
    String repoRoot,
    String oldToken,
    String newToken,
  ) {
    // The root governance/legal files' *body text* (e.g. CLA.md's "contributing to
    // `flutter_template` (the \"Project\")") — found in a clone dry
    // run. Their legal-identity placeholders (`core/contracts/legal_facts`'
    // company name/address/emails) are a separate, deliberately
    // `rename`-untouched concern — see the root README's "After cloning"
    // checklist — and share no token with `oldToken` here, so one
    // substring pass safely rewrites the project name without touching
    // them.
    const proseFiles = [
      'README.md',
      'CLAUDE.md',
      'apps/app/README.md',
      'NOTICE',
      'CLA.md',
      'CONTRIBUTING.md',
      'SECURITY.md',
    ];
    for (final relativePath in proseFiles) {
      final file = File(p.join(repoRoot, relativePath));
      if (!file.existsSync()) continue;
      final content = file.readAsStringSync();
      final rewritten = replaceTemplateToken(
        content,
        oldToken: oldToken,
        newToken: newToken,
      );
      if (rewritten != content) file.writeAsStringSync(rewritten);
    }
  }

  void _rewriteI18nAppTitle(String repoRoot, String display) {
    for (final locale in const ['en', 'de']) {
      final file = File(
        p.join(repoRoot, 'apps', 'app', 'lib', 'i18n', '$locale.i18n.json'),
      );
      if (!file.existsSync()) continue;
      try {
        file.writeAsStringSync(
          rewriteI18nAppTitle(file.readAsStringSync(), display),
        );
      } on FormatException catch (e) {
        throw CommandFailure('${file.path}: $e');
      }
    }
    out(
      'Set the appTitle i18n placeholder to "$display" (regenerate with '
      '`melos run gen`, done below).',
    );
  }

  /// Rewrites `apps/website`'s own placeholder identity — its single
  /// `productName` constant (`lib/src/site_constants.dart`), which every
  /// page's `<title>`/nav/footer copy interpolates rather than repeating
  /// the literal string — to [display], the same display name
  /// `_rewriteI18nAppTitle` sets on `apps/app`. A cloned app's landing
  /// page and its app share one brand name; no separate `--website-name`
  /// flag. A no-op (not an error) if `apps/website` doesn't exist in this
  /// clone — the website is optional template content, not every clone
  /// necessarily keeps it.
  void _rewriteWebsiteIdentity(String repoRoot, String display) {
    final file = File(
      p.join(repoRoot, 'apps', 'website', 'lib', 'src', 'site_constants.dart'),
    );
    if (!file.existsSync()) return;
    try {
      file.writeAsStringSync(
        rewriteWebsiteProductName(file.readAsStringSync(), display),
      );
    } on FormatException catch (e) {
      throw CommandFailure('${file.path}: $e');
    }
    out('Set apps/website\'s productName placeholder to "$display".');
  }

  void _renameAppPackage(
    String repoRoot,
    String oldPackage,
    String newPackage,
  ) {
    final appDir = p.join(repoRoot, 'apps', 'app');
    final pubspecFile = File(p.join(appDir, 'pubspec.yaml'));
    pubspecFile.writeAsStringSync(
      rewritePubspecName(pubspecFile.readAsStringSync(), newPackage),
    );

    for (final subdir in const ['lib', 'test', 'bin', 'tool']) {
      _rewriteImportsUnder(
        Directory(p.join(appDir, subdir)),
        oldPackage: oldPackage,
        newPackage: newPackage,
      );
    }
    _rewriteDependencyKeys(
      repoRoot,
      oldPackage: oldPackage,
      newPackage: newPackage,
    );
    out(
      'Renamed the apps/app Dart package from "$oldPackage" to '
      '"$newPackage" and rewrote its package:$oldPackage/ imports.',
    );
  }

  void _rewriteImportsUnder(
    Directory dir, {
    required String oldPackage,
    required String newPackage,
  }) {
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      final rewritten = rewritePackageImports(
        content,
        oldPackage: oldPackage,
        newPackage: newPackage,
      );
      if (rewritten != content) entity.writeAsStringSync(rewritten);
    }
  }

  void _rewriteDependencyKeys(
    String repoRoot, {
    required String oldPackage,
    required String newPackage,
  }) {
    final keyPattern = RegExp('^  $oldPackage:\$', multiLine: true);
    for (final memberDir in _workspaceMemberDirs(repoRoot)) {
      if (memberDir == 'apps/app') continue;
      final pubspecFile = File(p.join(repoRoot, memberDir, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) continue;
      final content = pubspecFile.readAsStringSync();
      if (keyPattern.hasMatch(content)) {
        pubspecFile.writeAsStringSync(
          content.replaceAll(keyPattern, '  $newPackage:'),
        );
      }
    }
  }

  Future<void> _pubGet(String repoRoot) async {
    final result = await runner.run(
      'fvm',
      ['dart', 'pub', 'get'],
      workingDirectory: repoRoot,
      environment: _renameEnvironment,
    );
    if (result.exitCode != 0) {
      throw CommandFailure(
        'fvm dart pub get failed: ${result.stdout}\n${result.stderr}',
      );
    }
    out(
      'fvm dart pub get: resolved the workspace against the renamed '
      'pubspecs.',
    );
  }

  Future<void> _runMelosScript(String repoRoot, String script) async {
    final result = await runner.run(
      'fvm',
      ['dart', 'run', 'melos', 'run', script],
      workingDirectory: repoRoot,
      environment: _renameEnvironment,
    );
    if (result.exitCode != 0) {
      throw CommandFailure(
        'melos run $script failed:\n${result.stdout}\n${result.stderr}',
      );
    }
    out('melos run $script passed.');
  }

  void _checkNoLeftovers(String repoRoot, OldIdentity old) {
    final leftovers = findRenameLeftovers(
      repoRoot: repoRoot,
      searchTerms: old.leftoverSearchTerms.toList(),
      isAllowListed: (relativePath) =>
          p.posix.basename(relativePath) == 'CHANGELOG.md' ||
          renameLeftoverAllowList.contains(relativePath),
    );
    if (leftovers.isNotEmpty) {
      final formatted = leftovers.map((l) => '  $l').join('\n');
      throw CommandFailure(
        'rename left ${leftovers.length} old-name reference(s) behind:\n'
        '$formatted',
      );
    }
    out('No leftover references to the old name/org/display found.');
  }
}
