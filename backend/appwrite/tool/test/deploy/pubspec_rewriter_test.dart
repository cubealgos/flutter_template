import 'package:appwrite_tool/src/deploy/pubspec_rewriter.dart';
import 'package:test/test.dart';

const _originalYaml = '''
name: delete_account
publish_to: none
resolution: workspace

environment:
  sdk: ^3.13.0

dependencies:
  dart_appwrite: ^29.0.0
  domain:
    path: ../../../packages/domain

dev_dependencies:
  test: ^1.25.0
''';

void main() {
  test('drops resolution: workspace and dev_dependencies', () {
    final rewritten = const PubspecRewriter().rewrite(
      originalYaml: _originalYaml,
      lockedVersions: const <String, String>{'dart_appwrite': '29.0.0'},
      vendorPrefix: 'vendor',
    );

    expect(rewritten, isNot(contains('resolution: workspace')));
    expect(rewritten, isNot(contains('dev_dependencies')));
    expect(rewritten, isNot(contains('test:')));
  });

  test('pins a hosted dependency to the exact locked version', () {
    final rewritten = const PubspecRewriter().rewrite(
      originalYaml: _originalYaml,
      lockedVersions: const <String, String>{'dart_appwrite': '29.0.0'},
      vendorPrefix: 'vendor',
    );

    expect(rewritten, contains('dart_appwrite: 29.0.0'));
    expect(rewritten, isNot(contains('^29.0.0')));
  });

  test('repoints a path dependency at the vendor prefix', () {
    final rewritten = const PubspecRewriter().rewrite(
      originalYaml: _originalYaml,
      lockedVersions: const <String, String>{'dart_appwrite': '29.0.0'},
      vendorPrefix: 'vendor',
    );

    expect(rewritten, contains('domain:'));
    expect(rewritten, contains('path: vendor/domain'));
    expect(rewritten, isNot(contains('../../../packages/domain')));
  });

  test('throws when a hosted dependency has no locked version', () {
    expect(
      () => const PubspecRewriter().rewrite(
        originalYaml: _originalYaml,
        lockedVersions: const <String, String>{},
        vendorPrefix: 'vendor',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('handles a package with no dependencies at all', () {
    const yaml = '''
name: domain
environment:
  sdk: ^3.13.0
''';

    final rewritten = const PubspecRewriter().rewrite(
      originalYaml: yaml,
      lockedVersions: const <String, String>{},
      vendorPrefix: 'vendor',
    );

    expect(rewritten, contains('name: domain'));
    expect(rewritten, contains('dependencies: {}'));
  });
}
