import 'package:analyzer/dart/analysis/utilities.dart' show parseString;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:mvc_lints/src/view_detection.dart';
import 'package:test/test.dart';

/// Tests for the decision logic behind `AvoidViewNavigationCallsRule`:
/// [bannedNavigationCallDescription] (which calls are forbidden) combined
/// with [isViewCompilationUnit] (which files the rule even applies to) — the
/// same two things `AvoidViewNavigationCallsRule.registerNodeProcessors` and
/// its visitor use. The live proof that a view calling `context.go` fails
/// `melos run analyze` (criterion 6) is demonstrated separately against the
/// real plugin; these are the unit-level pass/fail cases for the rule logic.
///
/// Returns every [MethodInvocation] in [source], outermost first — e.g. for
/// `Navigator.of(context).pop()` this is `[.pop(), .of(...)]`, since `.pop()`
/// is visited before its target expression `Navigator.of(...)` is descended
/// into.
List<MethodInvocation> _methodInvocations(String source) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  final found = <MethodInvocation>[];
  unit.accept(_CollectMethodInvocations(found.add));
  return found;
}

class _CollectMethodInvocations extends RecursiveAstVisitor<void> {
  _CollectMethodInvocations(this.onFound);

  final void Function(MethodInvocation) onFound;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    onFound(node);
    super.visitMethodInvocation(node);
  }
}

void main() {
  group('bannedNavigationCallDescription — FAIL cases', () {
    test('Navigator.push', () {
      final calls = _methodInvocations(
        'void f() { Navigator.push(context, route); }',
      );
      expect(bannedNavigationCallDescription(calls.single), 'Navigator.push');
    });

    test('Navigator.of (the inner call chained off, not the outer .pop)', () {
      final calls = _methodInvocations(
        'void f() { Navigator.of(context).pop(); }',
      );
      // calls[0] is the outer `.pop()` call (target is the `Navigator.of(...)`
      // expression, not a bare identifier, so it is not itself flagged);
      // calls[1] is `Navigator.of(context)`, which is.
      expect(calls, hasLength(2));
      expect(bannedNavigationCallDescription(calls[1]), 'Navigator.of');
    });

    for (final method in bannedContextNavigationMethods) {
      test('context.$method', () {
        final calls = _methodInvocations(
          "void f() { context.$method('/home'); }",
        );
        expect(
          bannedNavigationCallDescription(calls.single),
          'context.$method',
        );
      });
    }
  });

  group('bannedNavigationCallDescription — PASS cases', () {
    test('an unrelated call on context', () {
      final calls = _methodInvocations(
        'void f() { context.findAncestorWidgetOfExactType(); }',
      );
      expect(bannedNavigationCallDescription(calls.single), isNull);
    });

    test('a call with no target', () {
      final calls = _methodInvocations("void f() { print('hi'); }");
      expect(bannedNavigationCallDescription(calls.single), isNull);
    });

    test('a call on an unrelated target that merely looks similar', () {
      final calls = _methodInvocations(
        'void f() { navigatorLike.push(route); }',
      );
      expect(bannedNavigationCallDescription(calls.single), isNull);
    });
  });

  test(
    'FAIL: a *_view.dart file calling context.go is in scope and banned',
    () {
      const source = '''
      class CounterView {
        void onTap() { context.go('/home'); }
      }
    ''';
      final unit = parseString(content: source, throwIfDiagnostics: false).unit;
      final isView = isViewCompilationUnit(
        path: 'lib/counter_view.dart',
        unit: unit,
      );
      final calls = _methodInvocations(source);

      expect(isView, isTrue);
      expect(bannedNavigationCallDescription(calls.single), 'context.go');
    },
  );

  test('PASS: the same call outside a view file is not in scope', () {
    const source = '''
      class CounterController {
        void onTap() { context.go('/home'); }
      }
    ''';
    final unit = parseString(content: source, throwIfDiagnostics: false).unit;
    final isView = isViewCompilationUnit(
      path: 'lib/counter_controller.dart',
      unit: unit,
    );

    // Not a view, so `AvoidViewNavigationCallsRule` never registers its
    // method-invocation visitor for this file — the call above would be
    // flagged by `bannedNavigationCallDescription` in isolation, but the
    // rule never runs it against this file.
    expect(isView, isFalse);
  });
}
