/// This repo's in-repo MVC-boundary analyzer plugin.
///
/// Referenced from the root `analysis_options.yaml` as a `path:` plugin
/// (`plugins: mvc_lints: path: core/architecture/mvc_lints`), resolved by the Dart
/// analysis server into its own synthetic package — never into the
/// workspace's own `dart pub get` — so this package's `analyzer: ^14.1.0`
/// constraint never touches the workspace's deliberate analyzer 10.x–13.x
/// pin. See `pubspec.yaml` in this directory and CLAUDE.md for the full
/// story.
///
/// This file must be `lib/main.dart` — the synthetic package's generated
/// `bin/plugin.dart` hard-codes `import 'package:mvc_lints/main.dart'`, not
/// `package:mvc_lints/mvc_lints.dart` or any other name.
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:mvc_lints/src/avoid_extra_widgets_in_view_files_rule.dart';
import 'package:mvc_lints/src/avoid_view_navigation_calls_rule.dart';
import 'package:mvc_lints/src/avoid_view_restricted_imports_rule.dart';

/// The plugin instance the analysis server loads — the entry point
/// `analysis_options.yaml`'s `plugins:` section resolves to.
final Plugin plugin = MvcLintsPlugin();

/// Enforces the MVC boundary: views stay
/// dumb and reach navigation, external URLs, the backend and data layer only
/// through an injected controller/service, never directly.
class MvcLintsPlugin extends Plugin {
  @override
  String get name => 'mvc_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(AvoidViewRestrictedImportsRule())
      ..registerWarningRule(AvoidViewNavigationCallsRule())
      ..registerWarningRule(AvoidExtraWidgetsInViewFilesRule());
  }
}
