import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/root_licence.dart';

import 'support/temp_workspace.dart';

/// This workspace's own real root `LICENSE` — read directly (not copied
/// into a fixture) so this test also proves [readRootLicenceSpdxId]
/// correctly identifies the exact file `melos run sbom` reads at the real
/// repo root.
File get _realRootLicenceFile =>
    File(p.join(Directory.current.path, '..', '..', '..', 'LICENSE'));

void main() {
  // Assigned in setUp/read throughout the tests, cleaned up in tearDown —
  // the standard package:test fixture-per-test pattern.
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;

  setUp(() => workspace = TempWorkspace.create('root_licence_'));
  tearDown(() => workspace.dispose());

  test('detects Apache-2.0 from its own opening header', () {
    expect(
      detectRootLicenceSpdxId('''
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/
'''),
      'Apache-2.0',
    );
  });

  test('returns null for unrecognised licence text', () {
    expect(detectRootLicenceSpdxId('Some bespoke licence text.'), isNull);
  });

  test('returns null for an MIT licence text', () {
    expect(
      detectRootLicenceSpdxId('''
MIT License

Copyright (c) 2026 Someone
'''),
      isNull,
    );
  });

  test("reads and identifies the workspace repo's own real root LICENSE", () {
    expect(
      _realRootLicenceFile.existsSync(),
      isTrue,
      reason:
          'run from core/tooling/tooling, so ../../../LICENSE is the '
          'repo root LICENSE',
    );

    expect(
      readRootLicenceSpdxId(_realRootLicenceFile.parent.path),
      'Apache-2.0',
    );
  });

  test('reading a repo root with no LICENSE file returns null', () {
    expect(readRootLicenceSpdxId(workspace.root.path), isNull);
  });

  test('reads and identifies a LICENSE file written to disk', () {
    workspace.writeFile('LICENSE', '''
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/
''');

    expect(readRootLicenceSpdxId(workspace.root.path), 'Apache-2.0');
  });
}
