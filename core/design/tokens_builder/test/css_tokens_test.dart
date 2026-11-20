import 'dart:io';

import 'package:test/test.dart';
import 'package:tokens_builder/src/css/build_css_tokens.dart';
import 'package:tokens_builder/src/css/css_emitter.dart';
import 'package:tokens_builder/src/css/css_token_model.dart';
import 'package:tokens_builder/src/dtcg/token_build_exception.dart';

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

/// One (input token JSON, expected declaration name, expected CSS value)
/// case for the table-driven leaf-conversion test below — avoids
/// near-identical repeated test bodies for every `$type`.
///
// This file's name describes the whole test suite, not this one fixture
// type — same convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class _LeafCase {
  const _LeafCase(this.description, this.tokenJson, this.name, this.value);

  final String description;
  final String tokenJson;
  final String name;
  final String value;
}

const _leafCases = [
  _LeafCase(
    'a px dimension passes through unchanged',
    r'{"space": {"4": {"$type": "dimension", "$value": "16px"}}}',
    'space-4',
    '16px',
  ),
  _LeafCase(
    'a rem dimension is NOT resolved to px (CSS honours it natively)',
    r'{"space": {"big": {"$type": "dimension", "$value": "1.5rem"}}}',
    'space-big',
    '1.5rem',
  ),
  _LeafCase(
    'an em dimension is allowed and passed through (the Dart pipeline '
        'rejects em outside a composite entry; CSS does not need to)',
    r'{"gap": {"$type": "dimension", "$value": "0.18em"}}',
    'gap',
    '0.18em',
  ),
  _LeafCase(
    'a bare unitless dimension defaults to px',
    r'{"gap": {"$type": "dimension", "$value": "4"}}',
    'gap',
    '4px',
  ),
  _LeafCase(
    'a duration converts to milliseconds',
    r'{"motion": {"fast": {"$type": "duration", "$value": "160ms"}}}',
    'motion-fast',
    '160ms',
  ),
  _LeafCase(
    'a fontWeight emits the bare CSS number',
    r'{"weight": {"$type": "fontWeight", "$value": 600}}',
    'weight',
    '600',
  ),
  _LeafCase(
    'a number line height emits a bare CSS number, never a length',
    r'{"line-height": {"body": {"$type": "number", "$value": 1.5}}}',
    'line-height-body',
    '1.5',
  ),
  _LeafCase(
    'a number scale value emits a bare CSS number',
    r'{"motion": {"press": {"scale": {"$type": "number", "$value": 0.98}}}}',
    'motion-press-scale',
    '0.98',
  ),
  _LeafCase(
    'a whole number stays whole',
    r'{"columns": {"$type": "number", "$value": 12}}',
    'columns',
    '12',
  ),
  _LeafCase(
    'a number alias resolves to the number',
    r'{"line-height": {"base": {"$type": "number", "$value": 1.4}, '
        r'"alias": {"$type": "number", "$value": "{line-height.base}"}}}',
    'line-height-alias',
    '1.4',
  ),
  _LeafCase(
    'a fontFamily emits a quoted, comma-joined CSS stack',
    r'{"font": {"body": {"$type": "fontFamily", '
        r'"$value": ["Geist", "sans-serif"]}}}',
    'font-body',
    '"Geist", sans-serif',
  ),
  _LeafCase(
    'a cubicBezier emits a CSS cubic-bezier() function',
    r'{"ease": {"$type": "cubicBezier", "$value": [0.2, 0.8, 0.2, 1]}}',
    'ease',
    'cubic-bezier(0.2, 0.8, 0.2, 1.0)',
  ),
  _LeafCase(
    'a string token passes through as a bare CSS keyword value',
    r'{"style": {"$type": "string", "$value": "italic"}}',
    'style',
    'italic',
  ),
];

void main() {
  group('buildCssTokensFromSources (synthetic leaf conversions)', () {
    for (final c in _leafCases) {
      test(c.description, () {
        final result = buildCssTokensFromSources(_fixture(other: c.tokenJson));
        final decl = result.base.singleWhere((d) => d.name == c.name);
        expect(decl.value, c.value);
      });
    }

    for (final c in buildErrorCases) {
      test(c.description, () {
        expectBuildError(
          () => buildCssTokensFromSources(_fixture(other: c.tokenJson)),
          c.mentions,
        );
      });
    }

    test('an invalid fontWeight is a build error', () {
      const json = r'{"weight": {"$type": "fontWeight", "$value": 601}}';
      expect(
        () => buildCssTokensFromSources(_fixture(other: json)),
        throwsA(isA<TokenBuildException>()),
      );
    });

    test('composite typography fields each become their own custom property '
        '(no shorthand assembly)', () {
      final result = buildCssTokensFromSources(
        _fixture(
          other: r'''
          {"typography": {"title": {
            "font-size": {"$type": "dimension", "$value": "1.75rem"},
            "font-weight": {"$type": "fontWeight", "$value": 400}
          }}}
          ''',
        ),
      );
      final names = result.base.map((d) => d.name).toSet();
      expect(
        names,
        containsAll([
          'typography-title-font-size',
          'typography-title-font-weight',
        ]),
      );
    });
  });

  group('buildCssTokensFromSources (synthetic colour themes)', () {
    test('light theme colours are exposed under key "light"', () {
      final result = buildCssTokensFromSources(_fixture());
      final light = result.colorsByTheme['light'];
      expect(light, isNotNull);
      expect(light?.single.name, 'color-a');
      expect(light?.single.value, '#ffffff');
    });

    test('dark overrides light for the same colour token', () {
      final result = buildCssTokensFromSources(_fixture());
      final dark = result.colorsByTheme['dark'];
      expect(dark?.single.value, '#000000');
    });

    test('an rgba() colour value passes through unchanged (not round-tripped '
        'through an ARGB int)', () {
      final result = buildCssTokensFromSources(
        _fixture(
          color:
              r'{"color": {"a": {"$type": "color", '
              r'"$value": "rgba(45, 49, 66, 0.12)"}}}',
        ),
      );
      final light = result.colorsByTheme['light'];
      expect(light?.single.value, 'rgba(45, 49, 66, 0.12)');
    });

    test('missing a required theme file is a build error', () {
      final lightOnly = _fixture()['color.light.json'];
      expect(lightOnly, isNotNull);
      final onlyLight = {'color.light.json': lightOnly ?? ''};
      expect(
        () => buildCssTokensFromSources(onlyLight),
        throwsA(isA<TokenBuildException>()),
      );
    });
  });

  group('emitCssSource', () {
    test('emits :root with base + light colours, then a dark media query', () {
      const result = CssBuildResult(
        base: [CssTokenDecl(name: 'space-4', value: '16px')],
        colorsByTheme: {
          'light': [CssTokenDecl(name: 'color-a', value: '#fff')],
          'dark': [CssTokenDecl(name: 'color-a', value: '#000')],
        },
      );
      final css = emitCssSource(result);

      expect(css, contains('GENERATED CODE - DO NOT MODIFY BY HAND'));
      final rootIndex = css.indexOf(':root {');
      final mediaIndex = css.indexOf('@media (prefers-color-scheme: dark)');
      expect(rootIndex, greaterThanOrEqualTo(0));
      expect(mediaIndex, greaterThan(rootIndex));
      final rootBlock = css.substring(rootIndex, mediaIndex);
      expect(rootBlock, contains('--space-4: 16px;'));
      expect(rootBlock, contains('--color-a: #fff;'));
      expect(css.substring(mediaIndex), contains('--color-a: #000;'));
    });

    test(r'a token $description becomes a comment above its declaration', () {
      const result = CssBuildResult(
        base: [
          CssTokenDecl(name: 'space-4', value: '16px', doc: 'Default gap.'),
        ],
        colorsByTheme: {'light': [], 'dark': []},
      );
      final css = emitCssSource(result);
      expect(css, contains('/* Default gap. */\n  --space-4: 16px;'));
    });
  });

  group('buildCssTokensFromSources + emitCssSource (real core/design/ui/tokens '
      'data)', () {
    test('produces valid, non-empty CSS with both light and dark blocks', () {
      final dir = Directory('../ui/tokens');
      final sources = <String, String>{
        for (final file in dir.listSync().whereType<File>())
          if (file.path.endsWith('.json'))
            file.uri.pathSegments.last: file.readAsStringSync(),
      };
      final result = buildCssTokensFromSources(sources);
      final css = emitCssSource(result);

      expect(css, contains('--color-accent:'));
      expect(css, contains('--space-4: 16px;'));
      expect(
        css,
        contains('--font-family-title: "Host Grotesk", system-ui, sans-serif;'),
      );
      expect(css, contains('@media (prefers-color-scheme: dark)'));
      // No chamfer/clip-path concept in the token set at all — the
      // generated CSS is plain custom properties, never a shape.
      expect(css, isNot(contains('clip-path')));
      expect(css, isNot(contains('chamfer')));
    });
  });
}
