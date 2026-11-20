import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

/// A phone-width viewport (inside the mobile breakpoint, below 768).
const double mobileWidth = 390;

/// A desktop-width viewport (at or above the 1024 desktop breakpoint).
const double desktopWidth = 1280;

/// The viewport height every [pumpLayout] uses.
const double layoutHeight = 800;

const double _bottomFraction = 0.8;
const double _half = 0.5;
const double _quarter = 0.25;

/// The y-coordinate below which a widget counts as pinned to the bottom of
/// the viewport.
const double bottomBand = layoutHeight * _bottomFraction;

/// The vertical middle of the viewport.
const double middle = layoutHeight * _half;

/// The y-coordinate above which a widget counts as top-anchored.
const double topBand = layoutHeight * _quarter;

/// A do-nothing callback for the layout parameters a test does not care
/// about; assignable to any `VoidCallback` or `ValueChanged<T>`.
// A callback that does nothing is the whole point of this helper.
// ignore: solid_lints/no_empty_block
void noop([Object? _]) {}

/// Pumps [layout] under a viewport of [width] x [layoutHeight] logical
/// pixels — the same `MediaQuery` size `ResponsiveLayout` measures — so a
/// layout is tested at the breakpoint it is meant for. The test surface is
/// resized to match (device pixel ratio 1), so the layout's own
/// `LayoutBuilder` constraints agree with the viewport.
Future<void> pumpLayout(
  WidgetTester tester,
  Widget layout, {
  required double width,
}) async {
  tester.view
    ..physicalSize = Size(width, layoutHeight)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromView(tester.view),
        child: AppTheme(child: layout),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
