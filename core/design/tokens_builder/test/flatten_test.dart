import 'package:test/test.dart';
import 'package:tokens_builder/src/dtcg/flatten.dart';
import 'package:tokens_builder/src/dtcg/token_build_exception.dart';

void main() {
  group('deepMergeTokenTrees', () {
    test('merges disjoint groups', () {
      final merged = deepMergeTokenTrees(
        {
          'a': {r'$type': 'color', r'$value': '#fff'},
        },
        {
          'b': {r'$type': 'color', r'$value': '#000'},
        },
      );
      expect(merged.keys, containsAll(<String>['a', 'b']));
    });

    test('is idempotent for identical content at the same path', () {
      final tree = {
        'a': {r'$type': 'color', r'$value': '#fff'},
      };
      final merged = deepMergeTokenTrees(tree, tree);
      expect(merged, tree);
    });

    test('conflicting content at the same path is a build error', () {
      expect(
        () => deepMergeTokenTrees(
          {
            'a': {r'$type': 'color', r'$value': '#fff'},
          },
          {
            'a': {r'$type': 'color', r'$value': '#000'},
          },
        ),
        throwsA(
          isA<TokenBuildException>().having(
            (e) => e.message,
            'message',
            contains('a'),
          ),
        ),
      );
    });
  });

  group('flattenTokenTree', () {
    test(r'inherits $type from an ancestor group', () {
      final result = flattenTokenTree({
        'motion': {
          r'$type': 'duration',
          'fast': {r'$value': '160ms'},
        },
      });
      expect(result.leaves['motion.fast']?.type, 'duration');
    });

    test(r'an own $type overrides the inherited one', () {
      final result = flattenTokenTree({
        'group': {
          r'$type': 'dimension',
          'child': {r'$type': 'color', r'$value': '#fff'},
        },
      });
      expect(result.leaves['group.child']?.type, 'color');
    });

    test(r'collects a group-level $description', () {
      final result = flattenTokenTree({
        'typography': {
          'title': {
            r'$description': 'Page H1',
            'font-size': {r'$type': 'dimension', r'$value': '12px'},
          },
        },
      });
      expect(result.groupDescriptions['typography.title'], 'Page H1');
    });
  });
}
