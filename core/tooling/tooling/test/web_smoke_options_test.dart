import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/web_smoke_options.dart';

void main() {
  test('no args means both chrome and only are unset', () {
    final options = parseWebSmokeArgs(const []);
    expect(options.chrome, isNull);
    expect(options.only, isNull);
  });

  test('parses --chrome', () {
    final options = parseWebSmokeArgs(const ['--chrome', '/path/to/chrome']);
    expect(options.chrome, '/path/to/chrome');
  });

  test('parses --only app', () {
    final options = parseWebSmokeArgs(const ['--only', 'app']);
    expect(options.only, 'app');
  });

  test('parses --only website', () {
    final options = parseWebSmokeArgs(const ['--only', 'website']);
    expect(options.only, 'website');
  });

  test('parses both flags together, in either order', () {
    final options = parseWebSmokeArgs(const [
      '--only',
      'app',
      '--chrome',
      '/c',
    ]);
    expect(options.chrome, '/c');
    expect(options.only, 'app');
  });

  test('rejects an unknown flag', () {
    expect(
      () => parseWebSmokeArgs(const ['--bogus', 'x']),
      throwsA(isA<CommandFailure>()),
    );
  });

  test('rejects a flag missing its value', () {
    expect(
      () => parseWebSmokeArgs(const ['--chrome']),
      throwsA(isA<CommandFailure>()),
    );
  });

  test('rejects an invalid --only value', () {
    expect(
      () => parseWebSmokeArgs(const ['--only', 'bogus']),
      throwsA(isA<CommandFailure>()),
    );
  });
}
