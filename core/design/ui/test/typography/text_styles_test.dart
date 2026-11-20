import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/text_styles.dart';

import '../support/app_harness.dart';

/// Pumps [text] styled with [style] under a themed harness, and returns
/// the resolved [TextStyle] the underlying [RichText] actually paints —
/// shared by every resolution test below so each only states what it
/// checks, not how to get there.
Future<TextStyle?> _resolvedStyle(
  WidgetTester tester,
  String text,
  TextStyler style,
) async {
  await tester.pumpWidget(testApp(StyledText(text, style: style)));

  final richText = tester.widget<RichText>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );

  return richText.text.style;
}

void main() {
  group('text style roles render without throwing', () {
    for (final entry in <String, TextStyler Function()>{
      'display': displayStyle,
      'h1': h1Style,
      'h2': h2Style,
      'h3': h3Style,
      'body': bodyStyle,
      'body-sm': bodySmStyle,
      'caption': captionStyle,
      'eyebrow': eyebrowStyle,
      'mono-data': monoDataStyle,
      'button': buttonStyle,
    }.entries) {
      testWidgets('the ${entry.key} role renders its text', (tester) async {
        await tester.pumpWidget(
          testApp(StyledText('Sample', style: entry.value())),
        );

        expect(find.text('Sample'), findsOneWidget);
      });
    }
  });

  group('heading and body resolution', () {
    testWidgets('h1Style resolves to productH1 at the h1 role weight', (
      tester,
    ) async {
      final style = await _resolvedStyle(tester, 'Title', h1Style());
      final context = tester.element(find.text('Title'));

      expect(style?.fontSize, productH1.resolve(context));
      expect(style?.fontWeight, FontWeight.w700);
      // Package-qualified: a bare family name is unreachable for a
      // package-bundled font and silently falls back to Roboto. Asserted
      // against the literal prefix, not `packageFontFamily(...)` itself,
      // so this test can't pass vacuously if that helper regressed.
      expect(style?.fontFamily, 'packages/ui/$fontFamilyTitle');
    });

    testWidgets('bodyStyle resolves to productBody at regular weight', (
      tester,
    ) async {
      final style = await _resolvedStyle(tester, 'Body copy', bodyStyle());
      final context = tester.element(find.text('Body copy'));

      expect(style?.fontSize, productBody.resolve(context));
      expect(style?.fontWeight, FontWeight.w400);
      expect(style?.fontFamily, 'packages/ui/$fontFamilyBody');
    });
  });

  group('data and label resolution', () {
    testWidgets('monoDataStyle uses the mono font family', (tester) async {
      final style = await _resolvedStyle(tester, '482913', monoDataStyle());

      expect(style?.fontFamily, 'packages/ui/$fontFamilyMono');
    });

    testWidgets('eyebrowStyle sets a non-zero letter-spacing', (tester) async {
      final style = await _resolvedStyle(tester, 'LABEL', eyebrowStyle());

      expect(style?.letterSpacing, greaterThan(0));
    });
  });

  group('color resolution', () {
    testWidgets('captionStyle resolves to the muted color, not ink', (
      tester,
    ) async {
      final style = await _resolvedStyle(tester, 'Fine print', captionStyle());
      final context = tester.element(find.text('Fine print'));

      expect(style?.color, colorFgSubtle.resolve(context));
      expect(style?.color, isNot(colorInk.resolve(context)));
    });

    testWidgets('buttonStyle does not force a color, unlike bodyStyle', (
      tester,
    ) async {
      final style = await _resolvedStyle(
        tester,
        'Continue',
        buttonStyle().color(colorOnAccent()),
      );
      final context = tester.element(find.text('Continue'));

      expect(style?.color, colorOnAccent.resolve(context));
    });
  });
}
