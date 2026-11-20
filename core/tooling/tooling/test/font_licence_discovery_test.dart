import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/font_licence_discovery.dart';

import 'support/temp_workspace.dart';

void main() {
  // Assigned in setUp/read throughout the tests, cleaned up in tearDown —
  // the standard package:test fixture-per-test pattern.
  // ignore: solid_lints/avoid_late_keyword
  late TempWorkspace workspace;

  setUp(() => workspace = TempWorkspace.create('font_licence_discovery_'));
  tearDown(() => workspace.dispose());

  test(
    'finds nothing when no package declares fonts (before any font is added)',
    () {
      final uiDir = Directory(
        p.join(workspace.root.path, 'core', 'design', 'ui'),
      )..createSync(recursive: true);
      workspace.writeFile(
        p.join('core', 'design', 'ui', 'pubspec.yaml'),
        'name: ui\n',
      );

      final found = discoverFontLicenceFiles(
        repoRoot: workspace.root.path,
        ownedDirs: [(packageName: 'ui', dir: uiDir)],
      );

      expect(found, isEmpty);
    },
  );

  test('finds OFL.txt under a declared flutter: fonts: asset dir', () {
    final uiDir = Directory(
      p.join(workspace.root.path, 'core', 'design', 'ui'),
    );
    workspace
      ..writeFile(p.join('core', 'design', 'ui', 'pubspec.yaml'), '''
name: ui
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
''')
      ..writeFile(
        p.join('core', 'design', 'ui', 'assets', 'fonts', 'OFL.txt'),
        'SIL Open Font License text',
      );

    final found = discoverFontLicenceFiles(
      repoRoot: workspace.root.path,
      ownedDirs: [(packageName: 'ui', dir: uiDir)],
    );

    expect(found, hasLength(1));
    expect(found.single.ownerPackage, 'ui');
    expect(p.basename(found.single.file.path), 'OFL.txt');
  });

  test('always scans apps/website/web/fonts even with no ownedDirs', () {
    workspace.writeFile(
      p.join('apps', 'website', 'web', 'fonts', 'LICENSE.txt'),
      'A font licence',
    );

    final found = discoverFontLicenceFiles(
      repoRoot: workspace.root.path,
      ownedDirs: const [],
    );

    expect(found, hasLength(1));
    expect(found.single.ownerPackage, 'apps');
  });

  test('finds OFL texts nested one subfolder deep under an always-scanned '
      'dir (each self-hosted font lives in its own subfolder)', () {
    workspace
      ..writeFile(
        p.join('apps', 'website', 'web', 'fonts', 'host-grotesk', 'OFL.txt'),
        'Host Grotesk SIL Open Font License text',
      )
      ..writeFile(
        p.join('apps', 'website', 'web', 'fonts', 'ibm-plex-mono', 'OFL.txt'),
        'IBM Plex Mono SIL Open Font License text',
      );

    final found = discoverFontLicenceFiles(
      repoRoot: workspace.root.path,
      ownedDirs: const [],
    );

    // The two font subfolders this test writes, above.
    const expectedFontCount = 2;
    expect(found, hasLength(expectedFontCount));
    expect(found.every((f) => f.ownerPackage == 'apps'), isTrue);
    final texts = found.map((f) => f.file.readAsStringSync()).toSet();
    expect(texts, {
      'Host Grotesk SIL Open Font License text',
      'IBM Plex Mono SIL Open Font License text',
    });
  });

  test('deduplicates a licence file shared by two font families', () {
    final uiDir = Directory(
      p.join(workspace.root.path, 'core', 'design', 'ui'),
    );
    workspace
      ..writeFile(p.join('core', 'design', 'ui', 'pubspec.yaml'), '''
name: ui
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Bold.ttf
''')
      ..writeFile(
        p.join('core', 'design', 'ui', 'assets', 'fonts', 'OFL.txt'),
        'SIL Open Font License text',
      );

    final found = discoverFontLicenceFiles(
      repoRoot: workspace.root.path,
      ownedDirs: [(packageName: 'ui', dir: uiDir)],
    );

    expect(found, hasLength(1));
  });

  test('ignores a non-licence file in the font dir', () {
    final uiDir = Directory(
      p.join(workspace.root.path, 'core', 'design', 'ui'),
    );
    workspace
      ..writeFile(p.join('core', 'design', 'ui', 'pubspec.yaml'), '''
name: ui
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
''')
      ..writeFile(
        p.join('core', 'design', 'ui', 'assets', 'fonts', 'Inter-Regular.ttf'),
        'not a real font, just test bytes',
      );

    final found = discoverFontLicenceFiles(
      repoRoot: workspace.root.path,
      ownedDirs: [(packageName: 'ui', dir: uiDir)],
    );

    expect(found, isEmpty);
  });
}
