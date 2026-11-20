import 'package:test/test.dart';
import 'package:tokens_builder/src/dtcg/identifiers.dart';

void main() {
  group('pathToIdentifier', () {
    test('joins segments in camelCase', () {
      expect(pathToIdentifier('color.paper'), 'colorPaper');
      expect(
        pathToIdentifier('typography.node-name.font-size'),
        'typographyNodeNameFontSize',
      );
    });

    test('leaves a digit-leading segment unshifted', () {
      expect(pathToIdentifier('space.4'), 'space4');
      expect(pathToIdentifier('product.2xl'), 'product2xl');
    });

    test('handles a kebab-case key segment', () {
      expect(pathToIdentifier('color.paper-2'), 'colorPaper2');
      expect(pathToIdentifier('color.bg-subtle'), 'colorBgSubtle');
    });
  });
}
