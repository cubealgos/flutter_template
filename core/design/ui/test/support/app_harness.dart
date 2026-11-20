import 'package:flutter/widgets.dart';
import 'package:ui/src/theme/app_theme.dart';

// A test-only composition helper, not a reusable package widget — kept as
// a function (not a widget class) so call sites read as
// `testApp(AppButton(...))` rather than `const TestApp(child: AppButton(...))`.
// ignore: solid_lints/avoid_returning_widgets
/// Pumps [home] inside a minimal, Material-free app shell.
///
/// This package imports nothing Material-flavored anywhere, tests included,
/// so component tests use a bare [WidgetsApp] (for a [Navigator],
/// [MediaQuery], and localizations) instead of a Material app shell.
/// [AppTheme] is pinned to [brightness] (light by default) via the
/// app-level `builder`, so it wraps every route — including ones a
/// component pushes itself, like `showAppDialog`/`showAppSheet` — not just
/// [home].
Widget testApp(Widget home, {Brightness brightness = Brightness.light}) {
  return WidgetsApp(
    color: const Color(0xffffffff),
    home: home,
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, _, _) => builder(context),
    ),
    builder: (_, child) => Directionality(
      textDirection: TextDirection.ltr,
      // Safe: WidgetsApp always supplies a non-null child when built from
      // `home`/routes, as here — this harness never triggers the null case
      // the parameter type otherwise allows for.
      // ignore: solid_lints/avoid_non_null_assertion
      child: AppTheme(brightnessOverride: brightness, child: child!),
    ),
  );
}
