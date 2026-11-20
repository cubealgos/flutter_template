import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:data/data.dart';
import 'package:test/test.dart';

void main() {
  test('a version that is still current is accepted', () {
    requireVersion(
      'a',
      expected: '2026-01-01T00:00:00.000+00:00',
      actual: '2026-01-01T00:00:00.000+00:00',
    );
  });

  test('a stale version is refused with DataConflictError', () {
    expect(
      () => requireVersion(
        'a',
        expected: '2026-01-01T00:00:00.000+00:00',
        actual: '2026-01-01T00:00:05.000+00:00',
      ),
      throwsA(isA<DataConflictError>()),
    );
  });
}
