import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvc/mvc.dart';

const double _height = 800;

const double _phone = 390;
const double _mobileMax = 767;
const double _tabletMin = 768;
const double _tabletWidth = 800;
const double _tabletMax = 1023;
const double _desktopMin = 1024;
const double _desktopWidth = 1280;

// Test fixture first; the file is named after the class under test.
// ignore: solid_lints/prefer_match_file_name
class _Label extends StatelessWidget {
  const _Label(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label, textDirection: TextDirection.ltr);
}

class _Host extends StatelessWidget {
  const _Host({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQueryData(size: Size(width, _height)),
    child: child,
  );
}

/// A layout whose optional builders are present per [tablet] / [desktop].
class _Layout extends StatelessWidget {
  const _Layout({required this.tablet, required this.desktop});

  final bool tablet;
  final bool desktop;

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
    mobile: (_) => const _Label('mobile'),
    tablet: tablet ? (_) => const _Label('tablet') : null,
    desktop: desktop ? (_) => const _Label('desktop') : null,
  );
}

/// Which layout is on screen after pumping a viewport of [width].
Future<String?> _shown(
  WidgetTester tester,
  double width, {
  required bool tablet,
  required bool desktop,
}) async {
  await tester.pumpWidget(
    _Host(
      width: width,
      child: _Layout(tablet: tablet, desktop: desktop),
    ),
  );
  for (final label in ['mobile', 'tablet', 'desktop']) {
    if (find.text(label).evaluate().isNotEmpty) return label;
  }

  return null;
}

void main() {
  group('ResponsiveLayout fallback', () {
    // Per width: what shows for [mobile only, mobile+tablet,
    // mobile+desktop, all three].
    const expected = <(double, List<String>)>[
      (_phone, ['mobile', 'mobile', 'mobile', 'mobile']),
      (_mobileMax, ['mobile', 'mobile', 'mobile', 'mobile']),
      (_tabletMin, ['mobile', 'tablet', 'mobile', 'tablet']),
      (_tabletWidth, ['mobile', 'tablet', 'mobile', 'tablet']),
      (_tabletMax, ['mobile', 'tablet', 'mobile', 'tablet']),
      (_desktopMin, ['mobile', 'tablet', 'desktop', 'desktop']),
      (_desktopWidth, ['mobile', 'tablet', 'desktop', 'desktop']),
    ];
    const combinations = <(bool, bool)>[
      (false, false),
      (true, false),
      (false, true),
      (true, true),
    ];

    for (final (width, shows) in expected) {
      for (var i = 0; i < combinations.length; i++) {
        final (tablet, desktop) = combinations[i];
        testWidgets(
          'width $width, tablet: $tablet, desktop: $desktop shows ${shows[i]}',
          (tester) async {
            final shown = await _shown(
              tester,
              width,
              tablet: tablet,
              desktop: desktop,
            );
            expect(shown, shows[i]);
          },
        );
      }
    }
  });

  testWidgets('builds only the chosen layout', (tester) async {
    var mobileBuilds = 0;
    var desktopBuilds = 0;
    await tester.pumpWidget(
      _Host(
        width: _desktopWidth,
        child: ResponsiveLayout(
          mobile: (_) {
            mobileBuilds++;

            return const _Label('mobile');
          },
          desktop: (_) {
            desktopBuilds++;

            return const _Label('desktop');
          },
        ),
      ),
    );

    expect(mobileBuilds, 0);
    expect(desktopBuilds, 1);
  });

  testWidgets('switches layout when the viewport crosses a breakpoint', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Host(width: _phone, child: _Layout(tablet: false, desktop: true)),
    );
    expect(find.text('mobile'), findsOneWidget);

    await tester.pumpWidget(
      const _Host(
        width: _desktopWidth,
        child: _Layout(tablet: false, desktop: true),
      ),
    );
    expect(find.text('desktop'), findsOneWidget);
    expect(find.text('mobile'), findsNothing);
  });

  testWidgets('measures the viewport, not the parent constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Host(
        width: _desktopWidth,
        child: Center(
          child: SizedBox(
            width: _phone,
            child: _Layout(tablet: false, desktop: true),
          ),
        ),
      ),
    );

    expect(find.text('desktop'), findsOneWidget);
  });

  testWidgets('custom breakpoints override the defaults', (tester) async {
    await tester.pumpWidget(
      _Host(
        width: _tabletWidth,
        child: ResponsiveLayout(
          tabletMinWidth: _tabletWidth,
          desktopMinWidth: _desktopWidth,
          mobile: (_) => const _Label('mobile'),
          tablet: (_) => const _Label('tablet'),
        ),
      ),
    );

    expect(find.text('tablet'), findsOneWidget);
  });

  test('defaults are 768 and 1024 (the design system breakpoints)', () {
    expect(ResponsiveLayout.defaultTabletMinWidth, _tabletMin);
    expect(ResponsiveLayout.defaultDesktopMinWidth, _desktopMin);
  });
}
