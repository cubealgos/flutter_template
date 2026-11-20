import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/locked_package.dart';

import 'support/temp_workspace.dart';

void main() {
  // Assigned in setUp/read throughout the tests, cleaned up in tearDown —
  // the standard package:test fixture-per-test pattern.
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;

  setUp(() => workspace = TempWorkspace.create('locked_package_'));
  tearDown(() => workspace.dispose());

  test('returns only hosted packages, skipping path and sdk sources', () {
    final path = workspace.writeFile('pubspec.lock', '''
packages:
  some_hosted:
    dependency: "direct main"
    description:
      name: some_hosted
      url: "https://pub.dev"
    source: hosted
    version: "1.2.3"
  a_workspace_member:
    dependency: "direct main"
    description:
      path: packages/a_workspace_member
      relative: true
    source: path
    version: "0.0.0"
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
''');

    final result = hostedPackagesFromLockfile(path);

    expect(result, hasLength(1));
    expect(result.single.name, 'some_hosted');
    expect(result.single.version, '1.2.3');
  });

  test('an empty packages map yields no results', () {
    final path = workspace.writeFile('pubspec.lock', 'packages: {}\n');

    expect(hostedPackagesFromLockfile(path), isEmpty);
  });

  test('throws on a missing file', () {
    final path = p.join(workspace.root.path, 'missing.lock');

    expect(
      () => hostedPackagesFromLockfile(path),
      throwsA(isA<CommandFailure>()),
    );
  });

  test('throws when a lockfile has no top-level packages map', () {
    final path = workspace.writeFile('pubspec.lock', 'foo: bar\n');

    expect(
      () => hostedPackagesFromLockfile(path),
      throwsA(isA<CommandFailure>()),
    );
  });
}
