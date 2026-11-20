import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/src/components/code_field.dart';

import '../support/app_harness.dart';

/// A shorter-than-default code length, used to prove [AppCodeField.length]
/// is enforced as a hard `maxLength`, not just a hint.
const int _customLength = 4;

/// Enters [input] into the sole [EditableText] under a freshly pumped
/// [AppCodeField], and returns what [AppCodeField.onChanged] was last
/// called with — shared by both the digit-filtering and default-typing
/// tests below so their near-identical bodies aren't duplicated inline.
Future<String?> _typeInto(WidgetTester tester, String input) async {
  String? typed;

  await tester.pumpWidget(
    testApp(AppCodeField(label: 'Code', onChanged: (value) => typed = value)),
  );
  await tester.enterText(find.byType(EditableText), input);

  return typed;
}

void main() {
  group('AppCodeField rendering and accessibility', () {
    testWidgets('renders its visible label and accessible name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(const AppCodeField(label: '6-digit code')),
      );

      expect(find.text('6-digit code'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('6-digit code'))),
        isSemantics(isTextField: true),
      );
      handle.dispose();
    });

    testWidgets('errorText renders visibly and becomes the field hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(const AppCodeField(label: 'Code', errorText: 'Invalid code')),
      );

      expect(find.text('Invalid code'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Code'))),
        isSemantics(isTextField: true, hint: 'Invalid code'),
      );
      handle.dispose();
    });
  });

  group('AppCodeField input filtering', () {
    testWidgets('accepts digits and calls onChanged with the typed value', (
      tester,
    ) async {
      expect(await _typeInto(tester, '482913'), '482913');
    });

    testWidgets('filters out non-digit characters', (tester) async {
      expect(await _typeInto(tester, 'a1b2c3'), '123');
    });
  });

  group('AppCodeField length and autofill', () {
    testWidgets('enforces the configured length as a hard maxLength', (
      tester,
    ) async {
      String? typed;

      await tester.pumpWidget(
        testApp(
          AppCodeField(
            label: 'Code',
            length: _customLength,
            onChanged: (value) => typed = value,
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '123456789');

      expect(typed, '1234');
    });

    testWidgets('wires the one-time-code autofill hint', (tester) async {
      await tester.pumpWidget(testApp(const AppCodeField(label: 'Code')));

      // naked_ui implements autofill via its own `AutofillClient`
      // (`NakedTextFieldState.textInputConfiguration`), not via
      // `EditableText`'s own constructor parameter — so this checks the
      // hint reached `NakedTextField`, which is this package's actual
      // integration point, rather than reaching into naked_ui's internals.
      final field = tester.widget<NakedTextField>(find.byType(NakedTextField));
      expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
    });
  });

  group('AppCodeField enabled state', () {
    testWidgets('enabled: false reports as disabled', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(const AppCodeField(label: 'Code', enabled: false)),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Code'))),
        isSemantics(isTextField: true, hasEnabledState: true),
      );
      handle.dispose();
    });
  });
}
