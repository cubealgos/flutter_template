import 'package:data/data.dart';
import 'package:test/test.dart';

void main() {
  group('FakeVersionPolicy', () {
    test('defaults to allowed', () async {
      final policy = FakeVersionPolicy();

      final result = await policy.check('1.0.0');

      expect(result.blocked, isFalse);
    });

    test('returns the configured result regardless of the version', () async {
      final blocked = VersionCheckResult(
        blocked: true,
        updateUrl: Uri.parse('https://example.com/update'),
        message: 'too old',
      );
      final policy = FakeVersionPolicy(result: blocked);

      final result = await policy.check('0.0.1');

      expect(result.blocked, isTrue);
      expect(result.updateUrl, Uri.parse('https://example.com/update'));
    });
  });
}
