import 'package:app/app/di.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

/// The app's Material-free root widget.
///
/// `WidgetsApp.router` — never `MaterialApp.router` — per this template's
/// no-Material rule. Wired to the DI-registered [GoRouter] and the active
/// device locale, set from `main()` via `LocaleSettings.useDeviceLocaleSync()`
/// and falling back to `en` (see `slang.yaml`'s `fallback_strategy`).
///
/// [WidgetsApp.builder] wraps every route's content in exactly one
/// [AppTheme] — "as high as possible in the widget tree", per that
/// widget's own dartdoc — so every screen resolves its `core/design/ui`
/// styling against the same `MixScope` rather than each screen wrapping
/// itself individually. It also paints the theme's own [colorBg] behind
/// every route: `WidgetsApp`, unlike `MaterialApp`, paints no background
/// of its own, so without this every screen would sit on the browser's
/// plain white `<body>` regardless of theme — invisible in dark mode for
/// any `colorInk`-styled text (confirmed by hand against a dark-mode
/// screenshot while building the onboarding stepper).
class App extends StatelessWidget {
  /// Creates the app root.
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return TranslationProvider(
      child: Builder(
        builder: (context) {
          final locale = TranslationProvider.of(context).flutterLocale;

          return WidgetsApp.router(
            routerConfig: getIt<GoRouter>(),
            color: const Color(0xFF000000),
            title: t.appTitle,
            locale: locale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            builder: (_, child) => AppTheme(
              // Paints the themed page background behind every screen —
              // without this the browser's default (white) background
              // shows through, glaring in dark theme.
              child: Builder(
                builder: (context) => ColoredBox(
                  color: colorBg.resolve(context),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
