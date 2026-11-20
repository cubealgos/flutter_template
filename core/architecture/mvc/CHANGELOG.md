# Changelog

All notable changes to `mvc` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged `mvc-vX.Y.Z` (see
`docs/releasing.md`).

## [Unreleased]

### Added

- `ResponsiveLayout({required mobile, tablet, desktop})`: picks one of up to three
  `WidgetBuilder`s by viewport width (`MediaQuery`, not parent constraints), falling back
  desktop, else tablet, else mobile. Breakpoints default to 768 and 1024 (the design system's
  `Breakpoint.tablet`/`desktop`, mirrored rather than imported so `mvc` does not depend on `ui`).
- The template's MVC package: the view triad (`ViewModel`, `ViewController`, `ViewWidget`,
  `InheritedViewWidget`) vendored from `sprout_state` 0.3.0 (MIT-licensed), a
  `ValueNotifier` + `InheritedWidget` state layer with its public API and semantics kept
  identical to the upstream package.
- The injectable services a `ViewController` uses to reach outside itself without a view
  ever doing so directly: `NavigationService` (wraps `go_router`), `LauncherService`
  (external URLs), `DialogService` (overlay dialogs) and `ClipboardService` (system
  clipboard).
- The view/controller boundary this package is built around is enforced mechanically by
  `core/architecture/mvc_lints`, not by convention alone — see that package's own
  changelog.
