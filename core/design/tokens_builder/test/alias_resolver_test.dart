import 'package:test/test.dart';
import 'package:tokens_builder/src/dtcg/alias_resolver.dart';
import 'package:tokens_builder/src/dtcg/raw_leaf.dart';
import 'package:tokens_builder/src/dtcg/token_build_exception.dart';

RawLeaf _leaf(Object value) => RawLeaf(type: 'color', value: value);

void main() {
  group('resolveAliases', () {
    test('resolves a direct alias', () {
      final resolved = resolveAliases({
        'a': _leaf('{b}'),
        'b': _leaf('#ffffff'),
      });
      expect(resolved['a']?.value, '#ffffff');
    });

    test('resolves a chain of aliases', () {
      final resolved = resolveAliases({
        'a': _leaf('{b}'),
        'b': _leaf('{c}'),
        'c': _leaf('#000000'),
      });
      expect(resolved['a']?.value, '#000000');
      expect(resolved['b']?.value, '#000000');
    });

    test('a non-alias value passes through unchanged', () {
      final resolved = resolveAliases({'a': _leaf('#123456')});
      expect(resolved['a']?.value, '#123456');
    });

    test('a cycle is a build error naming the full chain', () {
      expect(
        () => resolveAliases({'a': _leaf('{b}'), 'b': _leaf('{a}')}),
        throwsA(
          isA<TokenBuildException>().having(
            (e) => e.message,
            'message',
            contains('a -> b -> a'),
          ),
        ),
      );
    });

    test('a reference to an unknown token is a build error', () {
      expect(
        () => resolveAliases({'a': _leaf('{missing}')}),
        throwsA(
          isA<TokenBuildException>().having(
            (e) => e.message,
            'message',
            contains('missing'),
          ),
        ),
      );
    });
  });
}
