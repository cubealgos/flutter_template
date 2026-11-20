import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('compareDottedVersions', () {
    test('equal versions compare to zero', () {
      expect(compareDottedVersions('1.2.3', '1.2.3'), 0);
    });

    test('an older major version is negative', () {
      expect(compareDottedVersions('1.9.9', '2.0.0'), lessThan(0));
    });

    test('a newer patch version is positive', () {
      expect(compareDottedVersions('1.2.4', '1.2.3'), greaterThan(0));
    });

    test('a missing segment is treated as zero', () {
      expect(compareDottedVersions('1.2', '1.2.0'), 0);
      expect(compareDottedVersions('1.2.1', '1.2'), greaterThan(0));
    });

    test('a non-numeric segment is treated as zero, not thrown', () {
      expect(() => compareDottedVersions('1.x.0', '1.0.0'), returnsNormally);
    });
  });
}
