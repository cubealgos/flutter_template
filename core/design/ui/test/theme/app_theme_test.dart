import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/theme/app_theme.dart';
import 'package:ui/src/tokens.g.dart';

void main() {
  group('AppTheme', () {
    testWidgets('resolves colorBg to the light value under light brightness', (
      tester,
    ) async {
      await tester.pumpWidget(
        const AppTheme(
          brightnessOverride: Brightness.light,
          child: _ColorProbe(token: colorBg),
        ),
      );

      final resolved = tester.widget<_ColorProbe>(find.byType(_ColorProbe));
      final context = tester.element(find.byType(_ColorProbe));
      expect(resolved.token.resolve(context), lightTokens.colors[colorBg]);
    });

    testWidgets('resolves colorBg to the dark value under dark brightness', (
      tester,
    ) async {
      await tester.pumpWidget(
        const AppTheme(
          brightnessOverride: Brightness.dark,
          child: _ColorProbe(token: colorBg),
        ),
      );

      final context = tester.element(find.byType(_ColorProbe));
      expect(colorBg.resolve(context), darkTokens.colors[colorBg]);
    });

    testWidgets('light and dark resolve to different colors for colorBg', (
      _,
    ) async {
      expect(lightTokens.colors[colorBg], isNot(darkTokens.colors[colorBg]));
    });

    testWidgets(
      'falls back to MediaQuery.platformBrightness with no override',
      (tester) async {
        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(platformBrightness: Brightness.dark),
            child: AppTheme(child: _ColorProbe(token: colorBg)),
          ),
        );

        final context = tester.element(find.byType(_ColorProbe));
        expect(colorBg.resolve(context), darkTokens.colors[colorBg]);
      },
    );
  });

  group('AppTheme default text style', () {
    testWidgets('provides a DefaultTextStyle in the body font, so a plain Text '
        'renders in the bundled font rather than falling back to Roboto', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: AppTheme(
              brightnessOverride: Brightness.light,
              child: Text('Plain'),
            ),
          ),
        ),
      );

      final context = tester.element(find.text('Plain'));
      final style = DefaultTextStyle.of(context).style;

      // Asserted against the literal prefix, not `packageFontFamily(...)`
      // itself, so this test can't pass vacuously if that helper
      // regressed.
      expect(style.fontFamily, 'packages/ui/$fontFamilyBody');
      expect(style.fontFamilyFallback, fontFamilyBodyFallback);
      expect(style.fontSize, lightTokens.doubles[productBody]);
      expect(style.color, lightTokens.colors[colorFg]);
    });
  });
}

/// A leaf widget that exists only so the test can grab a [BuildContext]
/// underneath the [AppTheme] it was pumped inside.
///
// This is the package's root test entry for AppTheme, conventionally named
// after the theme under test, not after this fixture — same convention as
// core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class _ColorProbe extends StatelessWidget {
  const _ColorProbe({required this.token});

  final ColorToken token;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
