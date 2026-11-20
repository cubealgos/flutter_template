import 'package:flutter_test/flutter_test.dart';
import 'package:mvc/mvc.dart';
import 'package:ui/ui.dart';

/// `ResponsiveLayout` (in `mvc`, which does not depend on `ui`) mirrors the
/// design system's breakpoint numbers; this is the one place both packages
/// are visible, so it fails if they ever drift apart.
void main() {
  test("ResponsiveLayout's default breakpoints match the design system's", () {
    expect(ResponsiveLayout.defaultTabletMinWidth, Breakpoint.tablet.minWidth);
    expect(
      ResponsiveLayout.defaultDesktopMinWidth,
      Breakpoint.desktop.minWidth,
    );
  });
}
