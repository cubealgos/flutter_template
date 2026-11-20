import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/components/button.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/text_styles.dart';

import '../support/app_harness.dart';

// A no-op callback so the buttons are interactive; nothing is asserted on it.
// ignore: solid_lints/no_empty_block
void _noop() {}

void main() {
  // The label must carry the variant's foreground colour. A plain Text
  // child used to fall back to black, invisible on dark secondary buttons.
  // Keyed by (variant, disabled).
  const cases = <(AppButtonVariant, bool), ColorToken>{
    (AppButtonVariant.primary, false): colorOnAccent,
    (AppButtonVariant.secondary, false): colorFg,
    (AppButtonVariant.destructive, false): colorOnAccent,
    (AppButtonVariant.destructiveOutlined, false): colorDanger,
    (AppButtonVariant.primary, true): colorOnAccent,
    (AppButtonVariant.secondary, true): colorDisabled,
    (AppButtonVariant.destructive, true): colorOnAccent,
    (AppButtonVariant.destructiveOutlined, true): colorDisabled,
  };

  // Both a plain Text and a StyledText whose style sets no colour of its own.
  final labels = <String, Widget Function()>{
    'Text': () => const Text('Label'),
    'StyledText': () => StyledText('Label', style: buttonStyle()),
  };

  for (final brightness in Brightness.values) {
    for (final MapEntry(key: kind, value: buildLabel) in labels.entries) {
      for (final MapEntry(key: (variant, disabled), value: token)
          in cases.entries) {
        final state = disabled ? 'disabled' : 'enabled';
        testWidgets('$state ${variant.name} $kind label uses ${token.name} '
            'in ${brightness.name}', (tester) async {
          await tester.pumpWidget(
            testApp(
              AppButton(
                semanticLabel: 'Label',
                onPressed: _noop,
                variant: variant,
                disabled: disabled,
                child: buildLabel(),
              ),
              brightness: brightness,
            ),
          );

          final label = find.descendant(
            of: find.byType(AppButton),
            matching: find.byType(RichText),
          );
          final rendered = tester.widget<RichText>(label).text.style?.color;
          final expected = token.resolve(tester.element(label));

          expect(rendered, expected);
        });
      }
    }
  }
}
