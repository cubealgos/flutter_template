import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/deploy/bundle_stager.dart';
import 'package:appwrite_tool/src/deploy/pubspec_lock.dart';
import 'package:appwrite_tool/src/repo_root.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final repoRoot = findRepoRoot(Directory.current);
  final lockfile = PubspecLock.parse(
    File(p.join(repoRoot.path, 'pubspec.lock')).readAsStringSync(),
  );

  test('stages api with domain vendored and pubspecs rewritten', () {
    const function = FunctionSchema(
      id: 'api',
      name: 'API',
      runtime: 'dart-3.12',
      entrypoint: 'lib/main.dart',
      path: 'backend/appwrite/functions/api',
    );
    final stager = BundleStager(repoRoot: repoRoot, lockfile: lockfile);

    final staged = stager.stage(function);
    addTearDown(() => staged.deleteSync(recursive: true));

    expect(File(p.join(staged.path, 'lib', 'main.dart')).existsSync(), isTrue);

    final vendoredDomainPubspec = File(
      p.join(staged.path, 'vendor', 'domain', 'pubspec.yaml'),
    );
    expect(vendoredDomainPubspec.existsSync(), isTrue);
    expect(
      File(p.join(staged.path, 'vendor', 'domain', 'lib', 'domain.dart'))
          .existsSync(),
      isTrue,
    );

    final functionPubspec = File(p.join(staged.path, 'pubspec.yaml'))
        .readAsStringSync();
    expect(functionPubspec, isNot(contains('resolution: workspace')));
    expect(functionPubspec, contains('path: vendor/domain'));
    expect(functionPubspec, isNot(contains('packages/domain')));

    // Neither pubspec should still carry a `dev_dependencies` block - the
    // deployed bundle never runs `dart test`.
    expect(functionPubspec, isNot(contains('dev_dependencies')));
    expect(
      vendoredDomainPubspec.readAsStringSync(),
      isNot(contains('dev_dependencies')),
    );
  });

  test('never stages the function or vendored package test/ directories', () {
    const function = FunctionSchema(
      id: 'api',
      name: 'API',
      runtime: 'dart-3.12',
      entrypoint: 'lib/main.dart',
      path: 'backend/appwrite/functions/api',
    );
    final stager = BundleStager(repoRoot: repoRoot, lockfile: lockfile);

    final staged = stager.stage(function);
    addTearDown(() => staged.deleteSync(recursive: true));

    expect(Directory(p.join(staged.path, 'test')).existsSync(), isFalse);
    expect(
      Directory(p.join(staged.path, 'vendor', 'domain', 'test')).existsSync(),
      isFalse,
    );
  });
}
