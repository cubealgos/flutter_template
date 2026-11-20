import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Extra directories always scanned for a font licence file, on top of
/// whatever a package's own `pubspec.yaml` `flutter: fonts:` section
/// declares (see [discoverFontLicenceFiles]) — `apps/website` is a Jaspr
/// **static** site (no Flutter dependency, so no pubspec `fonts:`
/// section at all) and serves any font it ships as a plain static asset
/// under `web/fonts/`, so that's the only way its font licences can ever
/// be found. Declared relative to the repo root; each is a no-op if it
/// doesn't exist. Scanned **recursively** (unlike a package's own declared
/// font dirs, below) — each self-hosted font here lives in its own
/// subfolder (`web/fonts/host-grotesk/OFL.txt`,
/// `web/fonts/ibm-plex-mono/OFL.txt`), not directly under `web/fonts/`
/// itself.
const List<String> alwaysScannedFontDirs = ['apps/website/web/fonts'];

/// Filenames recognised as a font's own licence note, matched
/// case-insensitively: `OFL.txt`/`OFL.md` (the SIL Open Font License —
/// the convention almost every open font family ships its licence
/// under), plus the same `LICENSE*`/`COPYING*` shapes
/// `licence_bundle_command.dart` already looks for in a pub-cache package
/// directory.
final RegExp fontLicenceFilePattern = RegExp(
  r'^(OFL(\.txt|\.md)?|LICENSE.*|COPYING.*)$',
  caseSensitive: false,
);

/// One font asset directory to scan: `packageName`'s own directory
/// (`dir`), used to resolve any `flutter: fonts:` asset paths its own
/// `pubspec.yaml` declares relative to itself.
typedef FontOwnedDir = ({String packageName, Directory dir});

/// One discovered font-licence file, and which package's font assets it
/// covers (for the licence bundle's own heading — see
/// `licence_bundle_command.dart`).
typedef FontLicenceFile = ({String ownerPackage, File file});

/// Finds every font-licence file reachable from [ownedDirs] (typically:
/// the target app's own directory, plus every first-party workspace
/// member in its dependency closure — see `licence_bundle_command.dart`)
/// and [alwaysScannedFontDirs] (resolved against [repoRoot]).
///
/// For each [ownedDirs] entry, this reads that package's own
/// `pubspec.yaml` `flutter: fonts:` section (if any) — a list of font
/// families, each a list of `{asset: <path>}` entries — and scans the
/// **directory** each declared asset lives in for a licence file, rather
/// than requiring one hard-coded font-asset directory name: whatever directory
/// a package actually declares its fonts under is scanned, generically, so this
/// keeps working however the font assets end up laying them out. Deduplicated
/// by resolved file path, so a licence file two different font families happen
/// to share is only ever reported once.
List<FontLicenceFile> discoverFontLicenceFiles({
  required String repoRoot,
  required List<FontOwnedDir> ownedDirs,
}) {
  final found = <String, FontLicenceFile>{};

  void scan(String ownerPackage, Directory dir, {required bool recursive}) {
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: recursive)) {
      if (entity is! File) continue;
      final base = p.basename(entity.path);
      if (!fontLicenceFilePattern.hasMatch(base)) continue;
      found.putIfAbsent(
        p.canonicalize(entity.path),
        () => (ownerPackage: ownerPackage, file: entity),
      );
    }
  }

  for (final owned in ownedDirs) {
    for (final fontDir in _declaredFontDirs(owned.dir)) {
      scan(owned.packageName, fontDir, recursive: false);
    }
  }
  for (final relative in alwaysScannedFontDirs) {
    scan(
      p.split(relative).first,
      Directory(p.join(repoRoot, relative)),
      recursive: true,
    );
  }

  return found.values.toList()
    ..sort((a, b) => a.file.path.compareTo(b.file.path));
}

/// Every directory [packageDir]'s own `pubspec.yaml` `flutter: fonts:`
/// section declares a font asset under, resolved to an absolute path.
/// Returns nothing if the package has no `pubspec.yaml`, no `flutter:`
/// key, or no `fonts:` list — all ordinary, not an error.
List<Directory> _declaredFontDirs(Directory packageDir) {
  final families = _fontFamilies(packageDir);
  final dirs = <String>{for (final family in families) ..._assetDirs(family)};

  return [for (final dir in dirs) Directory(p.join(packageDir.path, dir))];
}

/// [packageDir]'s own `pubspec.yaml` `flutter: fonts:` list, or an empty
/// list if the package has no `pubspec.yaml`, no `flutter:` key, or no
/// `fonts:` list.
YamlList _fontFamilies(Directory packageDir) {
  final pubspecFile = File(p.join(packageDir.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) return YamlList.wrap(const []);

  final doc = loadYaml(pubspecFile.readAsStringSync());
  final flutterSection = doc is YamlMap ? doc['flutter'] : null;
  final families = flutterSection is YamlMap ? flutterSection['fonts'] : null;

  return families is YamlList ? families : YamlList.wrap(const []);
}

/// Every asset directory one `fonts:` family entry (`{fonts: [{asset:
/// ...}, ...]}`) declares.
Iterable<String> _assetDirs(Object? family) sync* {
  if (family is! YamlMap || family['fonts'] is! YamlList) return;
  for (final font in family['fonts'] as YamlList) {
    final asset = font is YamlMap ? font['asset'] : null;
    if (asset is String) yield p.dirname(asset);
  }
}
