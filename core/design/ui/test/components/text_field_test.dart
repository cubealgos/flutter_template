import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/text_field.dart';

import '../support/app_harness.dart';

void main() {
  group('AppTextField rendering and accessibility', () {
    testWidgets('renders its visible label and accessible name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(testApp(const AppTextField(label: 'Email')));

      expect(find.text('Email'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Email'))),
        isSemantics(isTextField: true, isEnabled: true, hasEnabledState: true),
      );
      handle.dispose();
    });

    testWidgets('keyboard focus is reflected in semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(testApp(const AppTextField(label: 'Email')));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Email'))),
        isSemantics(isTextField: true, isFocused: true),
      );
      handle.dispose();
    });
  });

  group('AppTextField content', () {
    testWidgets('entering text calls onChanged with the typed value', (
      tester,
    ) async {
      String? changed;

      await tester.pumpWidget(
        testApp(
          AppTextField(label: 'Email', onChanged: (value) => changed = value),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'a@example.com');
      await tester.pump();

      expect(changed, 'a@example.com');
    });

    testWidgets('errorText renders visibly and becomes the field hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(const AppTextField(label: 'Email', errorText: 'Required')),
      );

      expect(find.text('Required'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Email'))),
        isSemantics(isTextField: true, hint: 'Required'),
      );
      handle.dispose();
    });

    testWidgets('obscureText: true marks the field as obscured', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(const AppTextField(label: 'Password', obscureText: true)),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Password'))),
        isSemantics(isTextField: true, isObscured: true),
      );
      handle.dispose();
    });
  });

  group('AppTextField enabled state', () {
    testWidgets('enabled: false reports as disabled', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        testApp(const AppTextField(label: 'Email', enabled: false)),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Email'))),
        isSemantics(isTextField: true, hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });
  });
}
