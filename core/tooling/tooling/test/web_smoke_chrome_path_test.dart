import 'package:test/test.dart';
import 'package:tooling/src/web_smoke_chrome_path.dart';

typedef _Case = ({
  String description,
  String? flagValue,
  Map<String, String> environment,
  bool isMacOS,
  String expected,
});

const List<_Case> _cases = <_Case>[
  (
    description: 'the --chrome flag wins over everything else',
    flagValue: '/custom/chrome',
    environment: {'CHROME': '/env/chrome'},
    isMacOS: true,
    expected: '/custom/chrome',
  ),
  (
    description: 'the CHROME env var wins when no flag is given',
    flagValue: null,
    environment: {'CHROME': '/env/chrome'},
    isMacOS: true,
    expected: '/env/chrome',
  ),
  (
    description: 'an empty --chrome flag falls through to the env var',
    flagValue: '',
    environment: {'CHROME': '/env/chrome'},
    isMacOS: false,
    expected: '/env/chrome',
  ),
  (
    description: 'macOS default is the Google Chrome.app path',
    flagValue: null,
    environment: {},
    isMacOS: true,
    expected: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  ),
  (
    description: 'non-macOS default is the bare "chromium" command',
    flagValue: null,
    environment: {},
    isMacOS: false,
    expected: 'chromium',
  ),
];

void main() {
  for (final testCase in _cases) {
    test(testCase.description, () {
      final path = resolveChromeExecutable(
        flagValue: testCase.flagValue,
        environment: testCase.environment,
        isMacOS: testCase.isMacOS,
      );
      expect(path, testCase.expected);
    });
  }
}
