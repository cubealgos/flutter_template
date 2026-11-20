import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:tokens_builder/src/emit/dart_emitter.dart';
import 'package:tokens_builder/src/model/build_tokens.dart';

final DartFormatter _formatter = DartFormatter(
  languageVersion: DartFormatter.latestLanguageVersion,
);

/// Regression test for the merge-surfaced defect where `tokens.g.dart` was
/// committed pre-formatted (by a manual `dart format` pass) but the
/// builder itself emitted unformatted source — invisible while
/// build_runner's cache skipped the builder, and a 39-line diff the moment
/// the cache was invalidated and it actually ran. `emitTokensSource` must
/// hand back source that is *already* `dart format`-stable, since
/// `melos run gen` is a bare `build_runner build` with no separate format
/// step.
void main() {
  group('emitTokensSource output is format-stable', () {
    test('for a small synthetic fixture', () {
      final result = buildTokensFromSources({
        'color.light.json':
            r'{"color": {"a": {"$type": "color", "$value": "#ffffff"}}}',
        'color.dark.json':
            r'{"color": {"a": {"$type": "color", "$value": "#000000"}}}',
        'dimension.json':
            r'{"space": {"4": {"$type": "dimension", "$value": "16px"}}}',
      });
      final source = emitTokensSource(result);

      expect(_formatter.format(source), source);
    });

    test('for a number token, which is emitted as a double constant', () {
      final result = buildTokensFromSources({
        'color.light.json':
            r'{"color": {"a": {"$type": "color", "$value": "#ffffff"}}}',
        'color.dark.json':
            r'{"color": {"a": {"$type": "color", "$value": "#000000"}}}',
        'number.json':
            r'{"line-height": {"body": {"$type": "number", "$value": 1.5}}}',
      });
      final source = emitTokensSource(result);

      expect(
        source,
        contains(
          "const DoubleToken lineHeightBody = DoubleToken('line-height.body');",
        ),
      );
      expect(source, contains('lineHeightBody: 1.5,'));
      expect(_formatter.format(source), source);
    });

    test('for the real core/design/ui/tokens data', () {
      final sources = <String, String>{
        for (final entry in Directory(
          '../ui/tokens',
        ).listSync().whereType<File>())
          if (entry.path.endsWith('.json'))
            entry.uri.pathSegments.last: entry.readAsStringSync(),
      };
      final source = emitTokensSource(buildTokensFromSources(sources));

      expect(_formatter.format(source), source);
    });
  });
}
