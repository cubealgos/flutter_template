import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/feature_names.dart';
import 'package:tooling/src/feature_templates.dart';
import 'package:tooling/src/process_runner.dart';
import 'package:tooling/src/router_edit.dart';
import 'package:yaml/yaml.dart';

/// `new_feature <path>`: scaffolds a feature under
/// `apps/app/lib/features/<path>/` following the structure rules in
/// `apps/app/README.md` ("Feature structure").
///
/// Creates the model, controller, view and `layouts/<name>_mobile_layout.dart`
/// (all documented), a view smoke test and a layout test under
/// `apps/app/test/features/<path>/`, and wires a `TypedGoRoute` into
/// `apps/app/lib/app/router.dart`: its path is the kebab-cased `<path>`
/// (`settings/notifications` -> `'settings/notifications'`), so a nested
/// feature sits under its parent's route path. If `router.dart` does not have
/// the expected shape it is left untouched and the exact snippets to add are
/// printed instead.
///
/// **Naming rule:** everything is named after the **last** path segment:
/// `settings/notifications` -> `notifications_view.dart`, `NotificationsView`,
/// `NotificationsController`, `NotificationsModel`, `NotificationsRoute`.
/// The parent segments only choose the folder and the route path, so the
/// parent folder must already exist.
///
/// Refuses (exit 1, nothing written) an existing feature or test folder, a
/// reserved segment (`widgets`, `layouts`, `steps`), a segment that is not
/// snake_case, a missing parent feature folder and a route class that
/// `router.dart` already declares. The generated code needs
/// `melos run gen` (for `router.g.dart`) before it compiles.
class NewFeatureCommand {
  /// Creates the command. [out]/[err] default to stdout/stderr; [runner]
  /// runs `dart format` over what was written.
  NewFeatureCommand({
    this.runner = const SystemProcessRunner(),
    this.out = _defaultOut,
    this.err = _defaultErr,
  });

  /// The process runner `dart format` is invoked through.
  final ProcessRunner runner;

  /// Sink for normal messages.
  final void Function(String) out;

  /// Sink for error messages.
  final void Function(String) err;

  static void _defaultOut(String message) => stdout.writeln(message);
  static void _defaultErr(String message) => stderr.writeln(message);

  /// Runs the command against the repository rooted at [repoRoot].
  Future<int> run(List<String> args, {required String repoRoot}) =>
      runCatchingFailures(() => _run(args, repoRoot), err);

  Future<void> _run(List<String> args, String repoRoot) async {
    if (args.length != 1) {
      throw CommandFailure(
        'Usage: new_feature <path>   (e.g. new_feature settings/notifications)',
        exitCode: usageExitCode,
      );
    }
    final names = FeatureNames.parse(args.single);
    final appDir = p.join(repoRoot, 'apps', 'app');
    final featuresDir = p.join(appDir, 'lib', 'features');
    if (!Directory(featuresDir).existsSync()) {
      throw CommandFailure(
        'apps/app/lib/features not found under $repoRoot — run from the '
        'repo root.',
      );
    }
    final libDir = p.joinAll(<String>[featuresDir, ...names.segments]);
    final testDir = p.joinAll(<String>[
      appDir,
      'test',
      'features',
      ...names.segments,
    ]);
    _refuseIfExists(names, libDir, testDir);
    _refuseIfParentMissing(names, featuresDir);

    final templates = FeatureTemplates(names, appPackage: _appPackage(appDir));
    final routerFile = File(p.join(appDir, 'lib', 'app', 'router.dart'));
    final edit = _planRouterEdit(routerFile, templates);

    final written = _writeFiles(templates, libDir, testDir);
    final newRouter = edit.source;
    if (newRouter != null) {
      routerFile.writeAsStringSync(newRouter);
      written.add(routerFile.path);
    }
    await _format(written, repoRoot);
    _report(written, repoRoot, templates, edit);
  }

  void _refuseIfParentMissing(FeatureNames names, String featuresDir) {
    final parentDir = p.joinAll(<String>[featuresDir, ...names.parentSegments]);
    if (!Directory(parentDir).existsSync()) {
      final parent = names.parentSegments.join('/');
      throw CommandFailure(
        'Parent feature "$parent" does not exist '
        '(apps/app/lib/features/$parent) — create the parent first.',
      );
    }
  }

  /// Writes every generated file and returns their absolute paths.
  // Reads the generated texts off the templates: that is its whole job.
  // ignore: solid_lints/feature_envy
  List<String> _writeFiles(
    FeatureTemplates templates,
    String libDir,
    String testDir,
  ) {
    final name = templates.names.name;
    final files = <String, String>{
      p.join(libDir, '${name}_model.dart'): templates.model(),
      p.join(libDir, '${name}_controller.dart'): templates.controller(),
      p.join(libDir, '${name}_view.dart'): templates.view(),
      p.join(libDir, 'layouts', '${name}_mobile_layout.dart'): templates
          .mobileLayout(),
      p.join(testDir, '${name}_view_test.dart'): templates.viewTest(),
      p.join(testDir, 'layouts', '${name}_mobile_layout_test.dart'): templates
          .layoutTest(),
    };
    for (final entry in files.entries) {
      File(entry.key)
        ..createSync(recursive: true)
        ..writeAsStringSync(entry.value);
    }

    return files.keys.toList();
  }

  void _report(
    List<String> written,
    String repoRoot,
    FeatureTemplates templates,
    RouterEditResult edit,
  ) {
    for (final path in written) {
      out('Created/updated ${p.relative(path, from: repoRoot)}');
    }
    if (edit.source == null) {
      out(
        'Did not edit apps/app/lib/app/router.dart (${edit.reason}). Add '
        'this by hand:\n\n${templates.manualSnippet()}',
      );
    }
    out(
      'Next: run `fvm dart run melos run gen` (regenerates router.g.dart), '
      'then `melos run analyze` and `melos run test`.',
    );
  }

  void _refuseIfExists(FeatureNames names, String libDir, String testDir) {
    for (final dir in <String>[libDir, testDir]) {
      if (Directory(dir).existsSync() || File(dir).existsSync()) {
        throw CommandFailure(
          'Feature "${names.path}" already exists ($dir) — refusing to '
          'overwrite.',
        );
      }
    }
  }

  String _appPackage(String appDir) {
    final pubspec = loadYaml(
      File(p.join(appDir, 'pubspec.yaml')).readAsStringSync(),
    );
    final name = pubspec is YamlMap ? pubspec['name'] : null;
    if (name is! String || name.isEmpty) {
      throw CommandFailure('apps/app/pubspec.yaml has no package name.');
    }

    return name;
  }

  /// Computes the router edit without writing; a name clash is a hard
  /// refusal, an unrecognised file shape falls back to printing.
  RouterEditResult _planRouterEdit(
    File routerFile,
    FeatureTemplates templates,
  ) {
    if (!routerFile.existsSync()) {
      return (source: null, reason: 'apps/app/lib/app/router.dart not found');
    }
    final result = RouterEdit(templates).apply(routerFile.readAsStringSync());
    if (result.reason?.contains('already declares') ?? false) {
      throw CommandFailure('${result.reason} — pick a different feature name.');
    }

    return result;
  }

  Future<void> _format(List<String> paths, String repoRoot) async {
    final result = await runner.run(Platform.resolvedExecutable, <String>[
      'format',
      ...paths,
    ], workingDirectory: repoRoot);
    if (result.exitCode != 0) {
      out(
        'Warning: dart format failed (${result.stderr}); run '
        '`melos run format`.',
      );
    }
  }
}
