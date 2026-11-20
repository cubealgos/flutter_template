import 'package:flutter/widgets.dart';

/// Picks one of up to three layouts by the **viewport** width, so a feature
/// view can render a phone, tablet or desktop arrangement of the same
/// screen without ever swapping out its controller.
///
/// A view that owns a `ViewController` builds one of these from its
/// `build` method; crossing a breakpoint only rebuilds the layout beneath
/// it, never the controller, so state (text being typed, scroll position
/// held by the controller, a step in flight) survives a window resize or a
/// rotation.
///
/// **Fallback.** Only [mobile] is required. A wider layout that a feature
/// does not provide falls back to the next narrower one: a viewport in the
/// desktop range uses [desktop], else [tablet], else [mobile]; a viewport in
/// the tablet range uses [tablet], else [mobile].
///
/// **Measurement source.** The width comes from `MediaQuery.sizeOf`, the
/// full viewport, never from the parent's `BoxConstraints`. A screen body
/// normally sits inside a width-capped content wrapper (for example a
/// 440 px auth column), where local constraints would never report a
/// desktop-wide window; the viewport is the one source that means the same
/// thing wherever the widget is placed. It also only rebuilds when the
/// size changes, not on unrelated `MediaQuery` updates such as the
/// keyboard's view insets.
///
/// **Breakpoints.** A viewport is *desktop* from [desktopMinWidth]
/// (inclusive), *tablet* from [tabletMinWidth] up to but excluding
/// [desktopMinWidth], and *mobile* below [tabletMinWidth]. The defaults,
/// [defaultTabletMinWidth] (768) and [defaultDesktopMinWidth] (1024), are the
/// values of the design system's `Breakpoint.tablet` and `Breakpoint.desktop`
/// in `core/design/ui`. This package deliberately does not depend on `ui`
/// (an architecture package should not import the component library, and the
/// design system's `Breakpoint` comes from `package:mix`), so the numbers are
/// mirrored here and a test in `apps/app` fails if they ever drift apart.
///
/// The layouts are [WidgetBuilder]s, so only the chosen one is built.
class ResponsiveLayout extends StatelessWidget {
  /// Creates a responsive layout.
  ///
  /// [desktopMinWidth] must be greater than [tabletMinWidth].
  const ResponsiveLayout({
    required this.mobile,
    super.key,
    this.tablet,
    this.desktop,
    this.tabletMinWidth = defaultTabletMinWidth,
    this.desktopMinWidth = defaultDesktopMinWidth,
  }) : assert(
         desktopMinWidth > tabletMinWidth,
         'desktopMinWidth must be greater than tabletMinWidth',
       );

  /// The default lower bound, in logical pixels, of the tablet range
  /// (inclusive): 768, mirroring the design system's `Breakpoint.tablet`.
  static const double defaultTabletMinWidth = 768;

  /// The default lower bound, in logical pixels, of the desktop range
  /// (inclusive): 1024, mirroring the design system's `Breakpoint.desktop`.
  static const double defaultDesktopMinWidth = 1024;

  /// The layout below [tabletMinWidth], and the fallback for every wider
  /// range that has no layout of its own.
  final WidgetBuilder mobile;

  /// The layout from [tabletMinWidth] up to [desktopMinWidth], or `null` to
  /// fall back to [mobile].
  final WidgetBuilder? tablet;

  /// The layout from [desktopMinWidth], or `null` to fall back to [tablet],
  /// then [mobile].
  final WidgetBuilder? desktop;

  /// The width, in logical pixels, from which the viewport counts as tablet.
  final double tabletMinWidth;

  /// The width, in logical pixels, from which the viewport counts as desktop.
  final double desktopMinWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final builder = width >= desktopMinWidth
        ? desktop ?? tablet ?? mobile
        : width >= tabletMinWidth
        ? tablet ?? mobile
        : mobile;

    return builder(context);
  }
}
