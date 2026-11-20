import 'package:test/test.dart';
import 'package:tokens_builder/src/dtcg/token_build_exception.dart';
import 'package:tokens_builder/src/dtcg/unit_conversion.dart';

void main() {
  group('resolveDimensionValue', () {
    test('px and a bare unitless number pass through unchanged', () {
      // A single table exercises both units — each raw/expected pair sits
      // inside this list literal rather than a bare `expect()` argument, so
      // it reads as a spec table rather than a loose numeric literal.
      const cases = [('16px', 16.0), ('0.8px', 0.8), ('4', 4.0)];
      for (final (raw, expected) in cases) {
        expect(resolveDimensionValue(raw, tokenPath: 't'), expected);
      }
    });

    test('rem is multiplied by 16', () {
      const cases = [('1rem', 16.0), ('1.75rem', 28.0)];
      for (final (raw, expected) in cases) {
        expect(resolveDimensionValue(raw, tokenPath: 't'), expected);
      }
    });

    test('em is resolved relative to a supplied basis', () {
      const fontSizePx = 7.5;
      final resolved = resolveDimensionValue(
        '0.18em',
        tokenPath: 't',
        emBasisPx: fontSizePx,
      );
      const expected = 1.35;
      expect(resolved, expected);
    });

    test('em with no basis is a build error naming the token', () {
      expect(
        () => resolveDimensionValue(
          '0.18em',
          tokenPath: 'typography.x.letter-spacing',
        ),
        throwsA(
          isA<TokenBuildException>().having(
            (e) => e.message,
            'message',
            contains('typography.x.letter-spacing'),
          ),
        ),
      );
    });

    test('an unknown unit is a build error naming the token', () {
      expect(
        () => resolveDimensionValue('5pt', tokenPath: 'some.token'),
        throwsA(
          isA<TokenBuildException>()
              .having((e) => e.message, 'message', contains('some.token'))
              .having((e) => e.message, 'message', contains('pt')),
        ),
      );
    });
  });

  group('resolveColorValue', () {
    test('parses a 6-digit hex color', () {
      final resolved = resolveColorValue('#f5f5f5', tokenPath: 't');
      const expected = 0xfff5f5f5;
      expect(resolved, expected);
    });

    test('parses an rgba() color', () {
      final resolved = resolveColorValue(
        'rgba(29, 111, 224, 0.08)',
        tokenPath: 't',
      );
      const expected = 0x141d6fe0;
      expect(resolved, expected);
    });

    test('an unrecognized color format is a build error naming the token', () {
      expect(
        () => resolveColorValue('hsl(0, 0%, 0%)', tokenPath: 'color.x'),
        throwsA(
          isA<TokenBuildException>().having(
            (e) => e.message,
            'message',
            contains('color.x'),
          ),
        ),
      );
    });
  });

  group('resolveDurationMilliseconds', () {
    test('parses a millisecond duration', () {
      final resolved = resolveDurationMilliseconds('160ms', tokenPath: 't');
      const expected = 160;
      expect(resolved, expected);
    });
  });

  group('resolveFontWeightConstantName', () {
    test('maps a supported weight', () {
      const weight = 600;
      final resolved = resolveFontWeightConstantName(weight, tokenPath: 't');
      expect(resolved, 'w600');
    });

    test('rejects an unsupported weight', () {
      const unsupportedWeight = 450;
      expect(
        () => resolveFontWeightConstantName(
          unsupportedWeight,
          tokenPath: 'font.x',
        ),
        throwsA(
          isA<TokenBuildException>().having(
            (e) => e.message,
            'message',
            contains('font.x'),
          ),
        ),
      );
    });
  });
}
