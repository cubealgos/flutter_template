import 'package:test/test.dart';
import 'package:tooling/src/linux_cmake_ids.dart';

/// A trimmed stand-in for `apps/app/linux/CMakeLists.txt`'s two `set(...)`
/// lines — the only two [readLinuxCmakeIds] reads.
const String _sampleCmakeLists = '''
set(BINARY_NAME "app")
set(APPLICATION_ID "de.example.app")
''';

void main() {
  test('extracts BINARY_NAME and APPLICATION_ID', () {
    final ids = readLinuxCmakeIds(_sampleCmakeLists);

    expect(ids.binaryName, 'app');
    expect(ids.applicationId, 'de.example.app');
  });

  test('throws a FormatException when BINARY_NAME is missing', () {
    expect(
      () => readLinuxCmakeIds('set(APPLICATION_ID "de.example.app")'),
      throwsFormatException,
    );
  });

  test('throws a FormatException when APPLICATION_ID is missing', () {
    expect(
      () => readLinuxCmakeIds('set(BINARY_NAME "app")'),
      throwsFormatException,
    );
  });
}
