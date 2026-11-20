import 'package:analyzer/dart/analysis/utilities.dart' show parseString;
import 'package:mvc_lints/src/view_detection.dart';
import 'package:test/test.dart';

/// Shared view-detection logic ([isViewCompilationUnit]) used by both
/// `avoid_view_restricted_imports_rule_test.dart` and
/// `avoid_view_navigation_calls_rule_test.dart` to decide whether a file is
/// in scope at all. Tested once, here.
void main() {
  group('isViewCompilationUnit', () {
    test('true for a file named *_view.dart with an unrelated class', () {
      final unit = parseString(
        content: 'class CounterView {}',
        throwIfDiagnostics: false,
      ).unit;
      expect(
        isViewCompilationUnit(path: 'lib/counter_view.dart', unit: unit),
        isTrue,
      );
    });

    test('true for a class extending ViewWidget regardless of file name', () {
      final unit = parseString(
        content: 'class Counter extends ViewWidget {}',
        throwIfDiagnostics: false,
      ).unit;
      expect(
        isViewCompilationUnit(path: 'lib/counter.dart', unit: unit),
        isTrue,
      );
    });

    test('true for a class extending InheritedViewWidget', () {
      final unit = parseString(
        content: 'class Counter extends InheritedViewWidget {}',
        throwIfDiagnostics: false,
      ).unit;
      expect(
        isViewCompilationUnit(path: 'lib/counter.dart', unit: unit),
        isTrue,
      );
    });

    for (final directory in ['widgets', 'layouts']) {
      test('true for a file under a $directory/ directory', () {
        final unit = parseString(
          content: 'class Row extends StatelessWidget {}',
          throwIfDiagnostics: false,
        ).unit;
        expect(
          isViewCompilationUnit(
            path: 'lib/features/home/$directory/row.dart',
            unit: unit,
          ),
          isTrue,
        );
      });
    }

    test('true for a widgets/ segment with Windows separators', () {
      final unit = parseString(
        content: 'class Row {}',
        throwIfDiagnostics: false,
      ).unit;
      expect(
        isViewCompilationUnit(path: r'lib\home\widgets\row.dart', unit: unit),
        isTrue,
      );
    });

    test('false when widgets is only part of a file or directory name', () {
      final unit = parseString(
        content: 'class Row {}',
        throwIfDiagnostics: false,
      ).unit;
      expect(
        isViewCompilationUnit(path: 'lib/my_widgets/row.dart', unit: unit),
        isFalse,
      );
      expect(
        isViewCompilationUnit(path: 'lib/home/widgets.dart', unit: unit),
        isFalse,
      );
    });

    test('false for a plain file with an unrelated superclass', () {
      final unit = parseString(
        content: 'class CounterController extends ChangeNotifier {}',
        throwIfDiagnostics: false,
      ).unit;
      expect(
        isViewCompilationUnit(path: 'lib/counter_controller.dart', unit: unit),
        isFalse,
      );
    });

    test('false for a file with no classes at all', () {
      final unit = parseString(
        content: r"String greet(String name) => 'hi $name';",
        throwIfDiagnostics: false,
      ).unit;
      expect(
        isViewCompilationUnit(path: 'lib/greet.dart', unit: unit),
        isFalse,
      );
    });
  });

  group('extraWidgetClasses', () {
    List<String> extras(String content) => extraWidgetClasses(
      parseString(content: content, throwIfDiagnostics: false).unit,
    ).map((c) => c.namePart.typeName.lexeme).toList();

    test('empty for a file with only its view', () {
      expect(extras('class A extends ViewWidget {}'), isEmpty);
    });

    test('flags other widgets declared around a ViewWidget', () {
      expect(
        extras('''
          class _Row extends StatelessWidget {}
          class A extends ViewWidget {}
          class _Card extends StatefulWidget {}
        '''),
        ['_Row', '_Card'],
      );
    });

    test('falls back to the first widget when there is no ViewWidget', () {
      expect(
        extras('''
          class A extends StatelessWidget {}
          class _B extends StatelessWidget {}
        '''),
        ['_B'],
      );
    });

    test('ignores State subclasses and non-widget classes', () {
      expect(
        extras('''
          class A extends StatefulWidget {}
          class _S extends State<A> {}
          enum E { a }
          class Plain {}
        '''),
        isEmpty,
      );
    });
  });
}
