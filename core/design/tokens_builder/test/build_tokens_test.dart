import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tokens_builder/src/model/build_tokens.dart';
import 'package:tokens_builder/src/model/resolved_token.dart';

import 'support/build_error_cases.dart';

Map<String, String> _fixture({
  String color = r'{"color": {"a": {"$type": "color", "$value": "#ffffff"}}}',
  String dark = r'{"color": {"a": {"$type": "color", "$value": "#000000"}}}',
  String other = '',
}) => {
  'color.light.json': color,
  'color.dark.json': dark,
  if (other.isNotEmpty) 'dimension.json': other,
};

/// Builds a fixture with [otherJson] as its non-color token file, then
/// asserts the single scalar token at [path] resolved to
/// [expectedValueSource]. Shared by the px/rem/alias-chain cases below,
/// which differ only in these three values.
void _expectScalarValueSource(
  String otherJson,
  String path,
  String expectedValueSource,
) {
  final result = buildTokensFromSources(_fixture(other: otherJson));
  final token = result.scalars.singleWhere((s) => s.path == path);
  expect(token.valueSource, expectedValueSource);
}

void main() {
  group('buildTokensFromSources (synthetic fixtures)', () {
    test('space.4 resolves to 16.0', _testSpace4);
    test('a px token is never multiplied by 16', _testPxNotScaled);
    test('a rem token is multiplied by 16', _testRemScaled);
    test('an alias chain resolves through multiple hops', _testAliasChain);
    test('dark overrides light for a color token', _testDarkOverridesLight);
    test(
      'em letter-spacing in a composite entry uses its own font-size',
      _testCompositeEyebrow,
    );
    test('a number token becomes a double constant', _testNumber);
    for (final c in buildErrorCases) {
      test(c.description, () {
        expectBuildError(
          () => buildTokensFromSources(_fixture(other: c.tokenJson)),
          c.mentions,
        );
      });
    }
  });

  group('buildTokensFromSources (real core/design/ui/tokens data)', () {
    test('space.4 resolves to 16.0', _testRealSpace4);
    test(
      'no px-suffixed source token was multiplied by 16',
      _expectNoPxTokenScaled,
    );
    test(
      'dark overrides light for every color token',
      _testRealDarkOverridesLight,
    );
  });
}

void _testNumber() {
  const json =
      r'{"line-height": {"body": {"$type": "number", "$value": 1.5}}, '
      r'"scale": {"$type": "number", "$value": 2}}';
  final result = buildTokensFromSources(_fixture(other: json));

  final lineHeight = result.scalars.singleWhere(
    (s) => s.path == 'line-height.body',
  );
  expect(lineHeight.kind, ScalarTokenKind.double_);
  expect(lineHeight.valueSource, '1.5');
  expect(lineHeight.identifier, 'lineHeightBody');
  // An integer in the JSON is still a `double` in the generated constant.
  expect(
    result.scalars.singleWhere((s) => s.path == 'scale').valueSource,
    '2.0',
  );
}

void _testSpace4() {
  final result = buildTokensFromSources(
    _fixture(
      other: r'{"space": {"4": {"$type": "dimension", "$value": "16px"}}}',
    ),
  );
  final token = result.scalars.singleWhere((s) => s.path == 'space.4');
  expect(token.kind, ScalarTokenKind.space);
  expect(token.valueSource, '16.0');
}

void _testPxNotScaled() {
  _expectScalarValueSource(
    r'{"stroke": {"thin": {"$type": "dimension", "$value": "0.8px"}}}',
    'stroke.thin',
    '0.8',
  );
}

void _testRemScaled() {
  _expectScalarValueSource(
    r'{"product": {"xs": {"$type": "dimension", "$value": "0.75rem"}}}',
    'product.xs',
    '12.0',
  );
}

void _testAliasChain() {
  _expectScalarValueSource(
    r'''
{
  "a": {"$type": "duration", "$value": "{b}"},
  "b": {"$type": "duration", "$value": "{c}"},
  "c": {"$type": "duration", "$value": "160ms"}
}
''',
    'a',
    'Duration(milliseconds: 160)',
  );
}

void _testDarkOverridesLight() {
  final result = buildTokensFromSources(_fixture());
  final token = result.colors.singleWhere((c) => c.path == 'color.a');
  const white = 0xffffffff;
  const black = 0xff000000;
  expect(token.argbByTheme['light'], white);
  expect(token.argbByTheme['dark'], black);
}

void _testCompositeEyebrow() {
  final result = buildTokensFromSources(
    _fixture(
      other: r'''
{
  "typography": {
    "eyebrow": {
      "$description": "Eyebrow style",
      "font-size": {"$type": "dimension", "$value": "7.5px"},
      "letter-spacing": {"$type": "dimension", "$value": "0.18em"}
    }
  }
}
''',
    ),
  );
  final token = result.scalars.singleWhere(
    (s) => s.path == 'typography.eyebrow',
  );
  expect(token.kind, ScalarTokenKind.textStyle);
  expect(token.valueSource, 'TextStyle(fontSize: 7.5, letterSpacing: 1.35)');
  expect(token.doc, 'Eyebrow style');
}

void _testRealSpace4() {
  final result = buildTokensFromSources(_loadRealSources());
  final token = result.scalars.singleWhere((s) => s.path == 'space.4');
  expect(token.valueSource, '16.0');
}

void _testRealDarkOverridesLight() {
  final result = buildTokensFromSources(_loadRealSources());
  final differing = result.colors.where(
    (c) => c.argbByTheme['light'] != c.argbByTheme['dark'],
  );
  expect(differing, isNotEmpty);
}

final Directory _tokensDir = Directory('../ui/tokens');

Map<String, String> _loadRealSources() {
  final sources = <String, String>{};
  for (final entry in _tokensDir.listSync().whereType<File>()) {
    if (entry.path.endsWith('.json')) {
      sources[entry.uri.pathSegments.last] = entry.readAsStringSync();
    }
  }

  return sources;
}

void _expectNoPxTokenScaled() {
  final sources = _loadRealSources();
  final result = buildTokensFromSources(sources);
  final pxByPath = _findAllPxLiterals(sources);
  final byPath = {for (final s in result.scalars) s.path: s};
  for (final entry in pxByPath.entries) {
    _expectPxUnscaled(entry.key, entry.value, byPath, result.scalars);
  }
  expect(pxByPath, isNotEmpty);
}

void _expectPxUnscaled(
  String path,
  double rawPx,
  Map<String, ResolvedScalarToken> byPath,
  List<ResolvedScalarToken> scalars,
) {
  final token = byPath[path];
  if (token != null) {
    expect(
      _numberIn(token.valueSource),
      rawPx,
      reason: '$path must resolve to its raw px number unscaled',
    );

    return;
  }
  // Absorbed into a composite typography TextStyleToken instead of a
  // standalone scalar — check its fontSize field there.
  if (path.endsWith('.font-size')) {
    final parent = path.substring(0, path.length - '.font-size'.length);
    final composite = scalars.singleWhere((s) => s.path == parent);
    expect(
      composite.valueSource,
      contains('fontSize: $rawPx'),
      reason: '$parent must carry its raw px font-size unscaled',
    );
  }
}

/// Extracts the first numeric literal from a scalar token's Dart value
/// source, whether it's a bare double (`"16.0"`) or wrapped
/// (`"Radius.circular(4.0)"`).
double _numberIn(String valueSource) {
  final match = RegExp(r'-?[0-9]+\.[0-9]+').firstMatch(valueSource);
  if (match == null) {
    throw StateError('No numeric literal found in "$valueSource".');
  }

  // Safe: group 0 (the whole match) is never null once a match exists.
  // ignore: solid_lints/avoid_non_null_assertion
  return double.parse(match.group(0)!);
}

/// Scans every base (non-color) token file for `"$value": "<n>px"` leaves
/// and returns their numeric literal by dot-joined path, by walking the
/// same JSON shape the builder itself walks.
Map<String, double> _findAllPxLiterals(Map<String, String> sources) {
  final result = <String, double>{};
  for (final entry in sources.entries) {
    if (entry.key.startsWith('color.') || entry.key == 'semantic.color.json') {
      continue;
    }
    final tree = jsonDecode(entry.value) as Map<String, dynamic>;
    _collectPx(tree, '', result);
  }

  return result;
}

void _collectPx(
  Map<String, dynamic> node,
  String path,
  Map<String, double> result,
) {
  final value = node[r'$value'];
  if (value is String) {
    final match = RegExp(r'^([0-9.]+)px$').firstMatch(value);
    if (match != null) {
      // Safe: this pattern's one capture group is mandatory whenever it
      // matches at all.
      // ignore: solid_lints/avoid_non_null_assertion
      result[path] = double.parse(match.group(1)!);
    }

    return;
  }
  for (final entry in node.entries) {
    if (entry.key.startsWith(r'$')) continue;
    _collectPx(
      entry.value as Map<String, dynamic>,
      path.isEmpty ? entry.key : '$path.${entry.key}',
      result,
    );
  }
}
