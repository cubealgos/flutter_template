// Re-exports `package:mix`'s own [Breakpoint] type rather than
// reinventing one: `Breakpoint.mobile` (`maxWidth: 767`),
// `Breakpoint.tablet` (`minWidth: 768, maxWidth: 1023`), and
// `Breakpoint.desktop` (`minWidth: 1024`) already match spec.md §1.1's
// breakpoint table exactly — "mobile <768px · tablet 768–1023px · desktop
// ≥1024px" — which is itself a verbatim reuse of the reference site's
// own `@media` breakpoints. Re-exported (rather than left for callers to
// import from `package:mix` directly) so every layout primitive in this
// package, including the app-design spec's own vocabulary for them, comes
// from one place: `package:ui/ui.dart`.
//
// Use [Breakpoint.matchesContext] to test the current viewport, or
// [Breakpoint.matches] against an explicit [Size] (e.g. from
// `LayoutBuilder`'s constraints) — see that class's own dartdoc for both.
export 'package:mix/mix.dart' show Breakpoint;
