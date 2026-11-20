import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/package_config_resolver.dart';

import 'support/temp_workspace.dart';

void main() {
  // Assigned in setUp/read throughout the tests, cleaned up in tearDown —
  // the standard package:test fixture-per-test pattern.
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;

  setUp(() => workspace = TempWorkspace.create('package_config_resolver_'));
  tearDown(() => workspace.dispose());

  test('resolves an absolute file:// rootUri as-is', () {
    final pubCacheDir = Directory(
      p.join(workspace.root.path, 'pub-cache', 'http-1.2.3'),
    )..createSync(recursive: true);
    workspace.writePackageConfig([
      {'name': 'http', 'rootUri': pubCacheDir.uri.toString()},
    ]);

    final resolver = PackageConfigResolver.load(workspace.root.path);

    expect(resolver.directoryFor('http')?.path, pubCacheDir.path);
  });

  test('resolves a relative rootUri against .dart_tool/, not repoRoot', () {
    workspace.writePackageConfig([
      {'name': 'app', 'rootUri': '../apps/app'},
    ]);
    final expected = p.normalize(p.join(workspace.root.path, 'apps', 'app'));

    final resolver = PackageConfigResolver.load(workspace.root.path);

    expect(resolver.directoryFor('app')?.path, expected);
  });

  test('returns null for a package not in the config', () {
    workspace.writePackageConfig(const []);

    final resolver = PackageConfigResolver.load(workspace.root.path);

    expect(resolver.directoryFor('no_such_package'), isNull);
  });

  test('throws CommandFailure when package_config.json is missing', () {
    expect(
      () => PackageConfigResolver.load(workspace.root.path),
      throwsA(isA<CommandFailure>()),
    );
  });

  test('throws CommandFailure on unparseable JSON', () {
    workspace.writeFile(
      p.join('.dart_tool', 'package_config.json'),
      'not json',
    );

    expect(
      () => PackageConfigResolver.load(workspace.root.path),
      throwsA(isA<CommandFailure>()),
    );
  });

  test("throws CommandFailure when there's no packages list", () {
    workspace.writeFile(
      p.join('.dart_tool', 'package_config.json'),
      jsonEncode({'configVersion': 2}),
    );

    expect(
      () => PackageConfigResolver.load(workspace.root.path),
      throwsA(isA<CommandFailure>()),
    );
  });
}
