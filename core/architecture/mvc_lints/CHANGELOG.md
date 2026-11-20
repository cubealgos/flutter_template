# Changelog

All notable changes to `mvc_lints` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged
`mvc_lints-vX.Y.Z` (see `docs/releasing.md`).

## [Unreleased]

### Added

- `avoid_extra_widgets_in_view_files` (`AvoidExtraWidgetsInViewFilesRule`): flags a
  `*_view.dart` that declares any widget class (`StatelessWidget`, `StatefulWidget`,
  `InheritedWidget` or the `ViewWidget` family) besides its view, pointing at `widgets/`.
- `avoid_view_restricted_imports` and `avoid_view_navigation_calls` now also treat any file
  under a `widgets/` or `layouts/` directory as a view.
- An in-repo analyzer plugin (`analysis_server_plugin`) enforcing the MVC boundary
  `core/architecture/mvc` is built around: a view (a file named `*_view.dart`, or a class
  extending `ViewWidget`/`InheritedViewWidget`) may not import navigation/network/data
  packages or call navigation APIs directly.
- Two rules: `AvoidViewRestrictedImportsRule` and `AvoidViewNavigationCallsRule`,
  registered on `MvcLintsPlugin`.
- Deliberately **not** a workspace member — it pins `analyzer: ^14.1.0`, which would
  otherwise force the whole workspace off its deliberate analyzer 10.x–13.x pin. Resolved
  independently (its own `dart pub get`, its own lockfile) and loaded by the Dart analysis
  server as a `path:` plugin declared in the root `analysis_options.yaml`.
- Tested via `melos run test:mvc_lints`, which resolves and tests it separately from the
  rest of the workspace.
