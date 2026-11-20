import 'package:test/test.dart';
import 'package:tooling/src/web_smoke_i18n.dart';

const String _fixture = '''
{
  "appTitle": "example_app",
  "signIn": {
    "title": "Sign in",
    "emailLabel": "Email address"
  }
}
''';

void main() {
  test('reads a top-level string', () {
    expect(readI18nString(_fixture, const ['appTitle']), 'example_app');
  });

  test('reads a nested string', () {
    expect(readI18nString(_fixture, const ['signIn', 'title']), 'Sign in');
  });

  test('throws FormatException for a missing key', () {
    expect(
      () => readI18nString(_fixture, const ['signIn', 'nope']),
      throwsFormatException,
    );
  });

  test('throws FormatException for a missing top-level key', () {
    expect(
      () => readI18nString(_fixture, const ['nope']),
      throwsFormatException,
    );
  });

  test('throws FormatException when the resolved value is not a string', () {
    expect(
      () => readI18nString(_fixture, const ['signIn']),
      throwsFormatException,
    );
  });
}
