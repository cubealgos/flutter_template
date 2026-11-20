import 'dart:convert';

import 'package:tokens_builder/src/dtcg/alias_resolver.dart';
import 'package:tokens_builder/src/dtcg/flatten.dart';
import 'package:tokens_builder/src/dtcg/identifiers.dart';
import 'package:tokens_builder/src/dtcg/raw_leaf.dart';
import 'package:tokens_builder/src/dtcg/source_classification.dart';
import 'package:tokens_builder/src/dtcg/token_build_exception.dart';
import 'package:tokens_builder/src/dtcg/unit_conversion.dart';
import 'package:tokens_builder/src/model/composite_typography.dart';
import 'package:tokens_builder/src/model/resolved_token.dart';

/// A DTCG `cubicBezier` value must have exactly this many control-point
/// numbers.
const int _cubicBezierPointCount = 4;

/// Runs the full DTCG → Dart pipeline: parses [jsonByFileName] (a token
/// source file's basename, e.g. `"dimension.json"`, mapped to its raw JSON
/// text), merges, resolves every alias, converts every unit explicitly, and
/// returns every declaration the emitter needs.
///
/// This is the pure, build_runner-independent entry point — both the real
/// `Builder` and the unit tests call it directly.
BuildTokensResult buildTokensFromSources(Map<String, String> jsonByFileName) {
  final parsed = jsonByFileName.map(
    (name, text) => MapEntry(name, jsonDecode(text) as Map<String, dynamic>),
  );
  final classified = classifySources(parsed, deepMerge: deepMergeTokenTrees);
  requireThemes(classified.themeFiles, const ['light', 'dark']);

  final baseFlat = flattenTokenTree(classified.base);
  final baseResolved = resolveAliases(baseFlat.leaves);
  final composite = extractCompositeTypography(
    baseFlat.groupDescriptions,
    baseResolved,
  );
  final scalars = [
    ...composite.tokens,
    ..._convertScalars(baseResolved, composite.consumedPaths),
  ];
  final plainConsts = _convertPlainConsts(
    baseResolved,
    composite.consumedPaths,
  );
  final themeResolved = resolveThemeLeaves(
    classified,
    deepMerge: deepMergeTokenTrees,
  );
  final colors = _buildColorTokens(themeResolved);

  return BuildTokensResult(
    themes: themeResolved.keys.toList()..sort(),
    colors: colors,
    scalars: scalars,
    plainConsts: plainConsts,
  );
}

const Map<String, ScalarTokenKind> _dimensionGroupKind = {
  'space': ScalarTokenKind.space,
  'radius': ScalarTokenKind.radius,
};

/// DTCG `$type`s that a *standalone* leaf never becomes a [ResolvedScalarToken]
/// for — `color` has its own themed pipeline, and the other three become
/// [PlainConstDecl]s instead (see [_convertPlainConsts]).
const Set<String> _nonScalarTypes = {
  'color',
  'fontFamily',
  'cubicBezier',
  'string',
};

List<ResolvedScalarToken> _convertScalars(
  Map<String, RawLeaf> leaves,
  Set<String> consumedPaths,
) {
  final result = <ResolvedScalarToken>[];
  for (final entry in leaves.entries) {
    if (consumedPaths.contains(entry.key)) continue;
    final scalar = _convertScalarLeaf(entry.key, entry.value);
    if (scalar != null) result.add(scalar);
  }

  return result;
}

ResolvedScalarToken? _convertScalarLeaf(String path, RawLeaf leaf) {
  if (_nonScalarTypes.contains(leaf.type)) return null;

  return switch (leaf.type) {
    'dimension' => _convertDimension(path, leaf),
    'duration' => _convertDuration(path, leaf),
    'fontWeight' => _convertFontWeight(path, leaf),
    'number' => _convertNumber(path, leaf),
    _ => throw TokenBuildException(
      'Token "$path" has an unsupported \$type "${leaf.type}".',
    ),
  };
}

ResolvedScalarToken _convertDimension(String path, RawLeaf leaf) {
  final value = resolveDimensionValue(leaf.value as String, tokenPath: path);
  final group = path.split('.').first;
  final kind = _dimensionGroupKind[group] ?? ScalarTokenKind.double_;
  final valueSource = kind == ScalarTokenKind.radius
      ? 'Radius.circular($value)'
      : '$value';

  return ResolvedScalarToken(
    path: path,
    identifier: pathToIdentifier(path),
    kind: kind,
    valueSource: valueSource,
    doc: leaf.description,
  );
}

ResolvedScalarToken _convertDuration(String path, RawLeaf leaf) {
  final ms = resolveDurationMilliseconds(leaf.value as String, tokenPath: path);

  return ResolvedScalarToken(
    path: path,
    identifier: pathToIdentifier(path),
    kind: ScalarTokenKind.duration,
    valueSource: 'Duration(milliseconds: $ms)',
    doc: leaf.description,
  );
}

/// A DTCG `number` becomes a `DoubleToken<double>`, the same bucket a
/// dimension outside `space` and `radius` lands in: the bare number as a
/// `double` literal (`1.5`, and `2` as `2.0`).
ResolvedScalarToken _convertNumber(String path, RawLeaf leaf) {
  final value = resolveNumberValue(leaf.value, tokenPath: path);

  return ResolvedScalarToken(
    path: path,
    identifier: pathToIdentifier(path),
    kind: ScalarTokenKind.double_,
    valueSource: '${value.toDouble()}',
    doc: leaf.description,
  );
}

ResolvedScalarToken _convertFontWeight(String path, RawLeaf leaf) {
  final name = resolveFontWeightConstantName(
    leaf.value as num,
    tokenPath: path,
  );

  return ResolvedScalarToken(
    path: path,
    identifier: pathToIdentifier(path),
    kind: ScalarTokenKind.fontWeight,
    valueSource: 'FontWeight.$name',
    doc: leaf.description,
  );
}

List<PlainConstDecl> _convertPlainConsts(
  Map<String, RawLeaf> leaves,
  Set<String> consumedPaths,
) {
  final result = <PlainConstDecl>[];
  for (final entry in leaves.entries) {
    if (consumedPaths.contains(entry.key)) continue;
    switch (entry.value.type) {
      case 'fontFamily':
        result.addAll(_convertFontFamily(entry.key, entry.value));
      case 'cubicBezier':
        result.add(_convertCubicBezier(entry.key, entry.value));
      case 'string':
        result.add(_convertStringConst(entry.key, entry.value));
    }
  }

  return result;
}

List<PlainConstDecl> _convertFontFamily(String path, RawLeaf leaf) {
  final families = (leaf.value as List).cast<String>();
  final id = pathToIdentifier(path);

  return [
    PlainConstDecl(
      identifier: id,
      dartType: 'String',
      valueSource: "'${families.first}'",
      doc: leaf.description,
    ),
    PlainConstDecl(
      identifier: '${id}Fallback',
      dartType: 'List<String>',
      valueSource:
          '<String>[${families.skip(1).map((f) => "'$f'").join(', ')}]',
      doc: 'Fallback families for [$id].',
    ),
  ];
}

PlainConstDecl _convertCubicBezier(String path, RawLeaf leaf) {
  final points = (leaf.value as List)
      .map((n) => (n as num).toDouble())
      .toList();
  if (points.length != _cubicBezierPointCount) {
    throw TokenBuildException(
      'Token "$path" has a cubicBezier value with ${points.length} numbers, '
      'expected $_cubicBezierPointCount.',
    );
  }

  return PlainConstDecl(
    identifier: pathToIdentifier(path),
    dartType: 'Cubic',
    valueSource: 'Cubic(${points.join(', ')})',
    doc: leaf.description,
  );
}

PlainConstDecl _convertStringConst(String path, RawLeaf leaf) {
  return PlainConstDecl(
    identifier: pathToIdentifier(path),
    dartType: 'String',
    valueSource: "'${leaf.value}'",
    doc: leaf.description,
  );
}

List<ResolvedColorToken> _buildColorTokens(
  Map<String, Map<String, RawLeaf>> themeResolved,
) {
  final sortedThemes = themeResolved.keys.toList()..sort();
  _requireMatchingColorPaths(themeResolved);

  final firstTheme = themeResolved[sortedThemes.first];
  if (firstTheme == null) {
    throw const TokenBuildException('No color theme resolved.');
  }

  return [
    for (final path in firstTheme.keys)
      _buildColorToken(path, sortedThemes, themeResolved),
  ];
}

void _requireMatchingColorPaths(
  Map<String, Map<String, RawLeaf>> themeResolved,
) {
  final entries = themeResolved.entries.toList();
  final referenceTheme = entries.first.key;
  final reference = entries.first.value.keys.toSet();
  for (final entry in entries.skip(1)) {
    final other = entry.value.keys.toSet();
    if (_setEquals(reference, other)) continue;
    throw TokenBuildException(
      'Color token set for theme "${entry.key}" does not match theme '
      '"$referenceTheme": missing ${reference.difference(other)}, '
      'extra ${other.difference(reference)}.',
    );
  }
}

bool _setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

ResolvedColorToken _buildColorToken(
  String path,
  List<String> themes,
  Map<String, Map<String, RawLeaf>> themeResolved,
) {
  final argbByTheme = <String, int>{};
  String? description;
  for (final theme in themes) {
    final leaf = themeResolved[theme]?[path];
    if (leaf == null) {
      throw TokenBuildException(
        'Token "$path" is missing from theme "$theme".',
      );
    }
    if (leaf.type != 'color') {
      throw TokenBuildException(
        'Token "$path" in a color theme file has \$type "${leaf.type}", '
        'expected "color".',
      );
    }
    argbByTheme[theme] = resolveColorValue(
      leaf.value as String,
      tokenPath: path,
    );
    description ??= leaf.description;
  }

  return ResolvedColorToken(
    path: path,
    identifier: pathToIdentifier(path),
    argbByTheme: argbByTheme,
    doc: description,
  );
}
