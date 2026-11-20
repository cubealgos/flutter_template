import 'package:analyzer/dart/analysis/utilities.dart' show parseString;
import 'package:mvc_lints/src/view_detection.dart';
import 'package:test/test.dart';

/// Tests for the decision logic behind `AvoidExtraWidgetsInViewFilesRule`:
/// [extraWidgetClasses] (which classes are flagged) — the rule itself only
/// adds the `*_view.dart` file-name gate on top.
List<String> _flagged(String source) => extraWidgetClasses(
  parseString(content: source, throwIfDiagnostics: false).unit,
).map((c) => c.namePart.typeName.lexeme).toList();

void main() {
  group('extraWidgetClasses — FAIL cases', () {
    test('a private StatelessWidget beside the view', () {
      expect(
        _flagged('''
          class CounterView extends ViewWidget {}
          class _Header extends StatelessWidget {}
        '''),
        ['_Header'],
      );
    });

    test('a StatefulWidget and an InheritedWidget beside the view', () {
      expect(
        _flagged('''
          class CounterView extends ViewWidget {}
          class Body extends StatefulWidget {}
          class Scope extends InheritedWidget {}
        '''),
        ['Body', 'Scope'],
      );
    });

    test('a second ViewWidget subclass', () {
      expect(
        _flagged('''
          class A extends ViewWidget {}
          class B extends ViewWidget {}
        '''),
        ['B'],
      );
    });
  });

  group('extraWidgetClasses — PASS cases', () {
    test('only the view class', () {
      expect(_flagged('class CounterView extends ViewWidget {}'), isEmpty);
    });

    test('a State class and an enum are not widgets', () {
      expect(
        _flagged('''
          class CounterView extends StatefulWidget {}
          class _CounterViewState extends State<CounterView> {}
          enum Mode { a, b }
        '''),
        isEmpty,
      );
    });
  });
}
