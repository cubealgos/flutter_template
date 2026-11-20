import 'package:test/test.dart';
import 'package:tooling/src/rename_text_rewrite.dart';

void main() {
  group('rewritePubspecName', () {
    test('rewrites only the top-level name: line, preserving comments', () {
      const content = '''
name: flutter_template_workspace
publish_to: none

# a comment mentioning name: as prose, never matched
environment:
  sdk: ^3.13.0
''';

      final rewritten = rewritePubspecName(content, 'acme_notes_workspace');

      expect(rewritten, contains('name: acme_notes_workspace'));
      expect(rewritten, isNot(contains('flutter_template_workspace')));
      expect(rewritten, contains('# a comment mentioning name: as prose'));
    });

    test('never touches a nested "name:" under dependencies', () {
      const content = '''
name: app
dependencies:
  mvc:
    path: ../../core/architecture/mvc
    name: mvc
''';

      final rewritten = rewritePubspecName(content, 'renamed_app');

      expect(rewritten, contains('name: renamed_app'));
      // The nested dependency's own `name:` (indented) is untouched.
      expect(rewritten, contains('    name: mvc'));
    });

    test('throws FormatException when there is no top-level name:', () {
      expect(
        () => rewritePubspecName('publish_to: none\n', 'x'),
        throwsFormatException,
      );
    });
  });

  group('replaceTemplateToken', () {
    test('replaces every occurrence of the old token', () {
      const content =
          'name: flutter_template_workspace\n'
          'description: The flutter_template default app.\n';

      final rewritten = replaceTemplateToken(
        content,
        oldToken: 'flutter_template',
        newToken: 'acme_notes',
      );

      expect(
        rewritten,
        'name: acme_notes_workspace\n'
        'description: The acme_notes default app.\n',
      );
    });

    test('is a no-op when the token is absent', () {
      const content = 'name: app\n';

      expect(
        replaceTemplateToken(
          content,
          oldToken: 'flutter_template',
          newToken: 'x',
        ),
        content,
      );
    });
  });

  group('rewritePackageImports', () {
    test('rewrites package:<old>/ import and export prefixes', () {
      const source = '''
import 'package:app/app/di.dart';
export 'package:app/features/sample/sample_view.dart';
import 'package:appwrite/appwrite.dart';
''';

      final rewritten = rewritePackageImports(
        source,
        oldPackage: 'app',
        newPackage: 'acme_notes',
      );

      expect(rewritten, contains("import 'package:acme_notes/app/di.dart';"));
      expect(
        rewritten,
        contains(
          "export 'package:acme_notes/features/sample/sample_view.dart';",
        ),
      );
      // A longer package name that merely starts with "app" is untouched.
      expect(rewritten, contains("import 'package:appwrite/appwrite.dart';"));
    });
  });

  group('rewriteI18nAppTitle', () {
    test('rewrites the appTitle field, keeping every other key', () {
      const json = '''
{
  "appTitle": "flutter_template",
  "sample": {
    "title": "Sample"
  }
}
''';

      final rewritten = rewriteI18nAppTitle(json, 'Acme Notes');

      expect(rewritten, contains('"appTitle": "Acme Notes"'));
      expect(rewritten, contains('"title": "Sample"'));
    });

    test('JSON-escapes a display name containing a quote', () {
      const json = '{"appTitle": "flutter_template"}';

      final rewritten = rewriteI18nAppTitle(json, 'Kev\'s "Notes"');

      expect(rewritten, contains('"appTitle": "Kev\'s \\"Notes\\""'));
    });

    test('throws FormatException when there is no appTitle field', () {
      expect(
        () => rewriteI18nAppTitle('{"sample": {}}', 'x'),
        throwsFormatException,
      );
    });
  });

  group('rewriteWebsiteProductName', () {
    test('rewrites the productName constant, keeping every other line', () {
      const dartSource = '''
/// Doc comment.
const String productName = 'Your Product';

const String productTagline = 'Replace this with your own product tagline.';
''';

      final rewritten = rewriteWebsiteProductName(dartSource, 'Acme Notes');

      expect(rewritten, contains("const String productName = 'Acme Notes';"));
      expect(
        rewritten,
        contains(
          "const String productTagline = 'Replace this with your own "
          "product tagline.';",
        ),
      );
    });

    test('escapes a display name containing a single quote', () {
      const dartSource = "const String productName = 'Your Product';";

      final rewritten = rewriteWebsiteProductName(dartSource, "Kev's Notes");

      expect(
        rewritten,
        contains(r"const String productName = 'Kev\'s Notes';"),
      );
    });

    test('throws FormatException when there is no productName constant', () {
      expect(
        () => rewriteWebsiteProductName('const String other = "x";', 'y'),
        throwsFormatException,
      );
    });
  });
}
