import 'package:tokens_builder/src/dtcg/alias_resolver.dart';
import 'package:tokens_builder/src/dtcg/flatten.dart';
import 'package:tokens_builder/src/dtcg/raw_leaf.dart';
import 'package:tokens_builder/src/dtcg/token_build_exception.dart';

/// Matches a colour-theme source file's basename, e.g. `color.light.json`
/// (capturing `light`) — the same convention [classifySources] and both
/// downstream emitters (`tokens.g.dart`, the generated CSS file) key their
/// theme discovery on.
final RegExp themeFilePattern = RegExp(r'^color\.([a-z0-9]+)\.json$');

/// The basename of the one token file whose colours apply to every theme
/// (merged into each `color.<theme>.json` tree before resolution) rather
/// than declaring their own theme-specific values.
const String semanticColorFileName = 'semantic.color.json';

/// The result of sorting every parsed `tokens/*.json` source into its role
/// in the pipeline, shared by both the Dart (`tokens.g.dart`) and CSS
/// emitters so a source file is only ever classified one way.
///
// This file groups the whole source-classification pass together, so its
// name doesn't match this first declaration — same convention as
// core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class ClassifiedSources {
  /// Creates a classification result.
  const ClassifiedSources({
    required this.themeFiles,
    required this.semanticColor,
    required this.base,
  });

  /// Every `color.<theme>.json` tree, by theme name.
  final Map<String, Map<String, dynamic>> themeFiles;

  /// `semantic.color.json`'s tree, if present — merged into every theme
  /// file before resolution.
  final Map<String, dynamic>? semanticColor;

  /// Every other source file, deep-merged into one tree — dimension,
  /// typography, motion and any further non-colour token group.
  final Map<String, dynamic> base;
}

/// Sorts [parsed] (a source file's basename mapped to its decoded JSON
/// tree) into [ClassifiedSources]: colour-theme files, the one semantic-
/// colour file, and everything else merged into a single `base` tree.
ClassifiedSources classifySources(
  Map<String, Map<String, dynamic>> parsed, {
  required Map<String, dynamic> Function(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  )
  deepMerge,
}) {
  final themeFiles = <String, Map<String, dynamic>>{};
  Map<String, dynamic>? semanticColor;
  var base = <String, dynamic>{};
  for (final entry in parsed.entries) {
    final themeMatch = themeFilePattern.firstMatch(entry.key);
    if (themeMatch != null) {
      // Safe: the pattern's one capture group is mandatory whenever it
      // matches at all.
      // ignore: solid_lints/avoid_non_null_assertion
      themeFiles[themeMatch.group(1)!] = entry.value;
    } else if (entry.key == semanticColorFileName) {
      semanticColor = entry.value;
    } else {
      base = deepMerge(base, entry.value);
    }
  }

  return ClassifiedSources(
    themeFiles: themeFiles,
    semanticColor: semanticColor,
    base: base,
  );
}

/// Throws [TokenBuildException] unless every theme name in [required] has a
/// matching `color.<theme>.json` file in [themeFiles].
void requireThemes(Map<String, dynamic> themeFiles, List<String> required) {
  final missing = required.where((theme) => !themeFiles.containsKey(theme));
  if (missing.isNotEmpty) {
    throw TokenBuildException(
      'No color.<theme>.json file found for required theme(s): '
      '${missing.join(', ')}.',
    );
  }
}

/// Merges each theme file in [classified] with the shared semantic-colour
/// tree (if any), then flattens and alias-resolves the result — one
/// `Map<path, RawLeaf>` per theme, ready for either emitter to read
/// `RawLeaf.value` from directly.
Map<String, Map<String, RawLeaf>> resolveThemeLeaves(
  ClassifiedSources classified, {
  required Map<String, dynamic> Function(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  )
  deepMerge,
}) {
  return {
    for (final entry in classified.themeFiles.entries)
      entry.key: resolveAliases(
        flattenTokenTree(deepMerge(entry.value, classified.semanticColor ?? {}))
            .leaves,
      ),
  };
}
