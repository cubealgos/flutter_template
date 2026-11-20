import 'package:analyzer/dart/analysis/utilities.dart' show parseString;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:mvc_lints/src/view_detection.dart';
import 'package:test/test.dart';

/// Tests for the decision logic behind `AvoidViewRestrictedImportsRule`:
/// [isBannedViewImport] (which import URIs are forbidden) combined with
/// [isViewCompilationUnit] (which files the rule even applies to) — the same
/// two calls `AvoidViewRestrictedImportsRule.registerNodeProcessors` and its
/// visitor make. See `AvoidViewRestrictedImportsRule`'s class doc for the
/// rule itself; criterion 6's "a view calling context.go fails analyze"-style
/// proof for the import rule (a view importing package:go_router failing
/// `melos run analyze`) is demonstrated separately against the live plugin,
/// not here — these are the unit-level pass/fail cases.
void main() {
  group('isBannedViewImport — FAIL cases (a view may not import these)', () {
    test('package:go_router', () {
      expect(isBannedViewImport('package:go_router/go_router.dart'), isTrue);
    });

    test('package:url_launcher', () {
      expect(
        isBannedViewImport('package:url_launcher/url_launcher.dart'),
        isTrue,
      );
    });

    test('package:appwrite', () {
      expect(isBannedViewImport('package:appwrite/appwrite.dart'), isTrue);
    });

    test('a relative import under repositories/', () {
      expect(
        isBannedViewImport('../repositories/user_repository.dart'),
        isTrue,
      );
    });

    test('a relative import under data/', () {
      expect(isBannedViewImport('../data/user_dto.dart'), isTrue);
    });

    test('a package import under a data/ path', () {
      expect(isBannedViewImport('package:app/data/user_dto.dart'), isTrue);
    });

    test('a package import under a repositories/ path', () {
      expect(
        isBannedViewImport('package:app/repositories/user_repository.dart'),
        isTrue,
      );
    });
  });

  group('isBannedViewImport — PASS cases (a view may import these)', () {
    test('an ordinary Flutter package', () {
      expect(isBannedViewImport('package:flutter/material.dart'), isFalse);
    });

    test('a sibling file outside repositories/ or data/', () {
      expect(isBannedViewImport('counter_controller.dart'), isFalse);
    });

    test('a models/ path (not repositories/ or data/)', () {
      expect(isBannedViewImport('../models/counter.dart'), isFalse);
    });
  });

  test(
    'FAIL: a *_view.dart file importing go_router is in scope and banned',
    () {
      final unit = parseString(
        content:
            "import 'package:go_router/go_router.dart';\n\n"
            'class CounterView {}',
        throwIfDiagnostics: false,
      ).unit;
      final isView = isViewCompilationUnit(
        path: 'lib/counter_view.dart',
        unit: unit,
      );
      final import = unit.directives.first as ImportDirective;
      final uri = import.uri.stringValue!;

      expect(isView, isTrue);
      expect(isBannedViewImport(uri), isTrue);
    },
  );

  test(
    'PASS: the same go_router import outside a view file is not in scope',
    () {
      final unit = parseString(
        content:
            "import 'package:go_router/go_router.dart';\n\n"
            'class CounterController {}',
        throwIfDiagnostics: false,
      ).unit;
      final isView = isViewCompilationUnit(
        path: 'lib/counter_controller.dart',
        unit: unit,
      );

      // Not a view at all, so `AvoidViewRestrictedImportsRule` never even
      // registers its import-directive visitor for this file.
      expect(isView, isFalse);
    },
  );
}
