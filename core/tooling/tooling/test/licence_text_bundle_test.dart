import 'package:test/test.dart';
import 'package:tooling/src/licence_text_bundle.dart';

void main() {
  test('an empty entry list still renders the preamble', () {
    final text = buildLicenceBundleText(const []);

    expect(text, contains('THIRD-PARTY LICENSES'));
    expect(text, contains('melos run licence-bundle'));
  });

  test('renders one underlined section per entry, in order', () {
    final text = buildLicenceBundleText(const [
      (heading: 'http 1.6.0', licenceText: 'MIT licence text'),
      (heading: 'meta 1.16.0', licenceText: 'BSD licence text'),
    ]);

    expect(text.indexOf('http 1.6.0'), lessThan(text.indexOf('meta 1.16.0')));
    expect(text, contains('-' * 'http 1.6.0'.length));
    expect(text, contains('MIT licence text'));
    expect(text, contains('BSD licence text'));
  });

  test('trims each licence text', () {
    final text = buildLicenceBundleText(const [
      (heading: 'pkg 1.0.0', licenceText: '\n\n  licence body  \n\n'),
    ]);

    expect(text, contains('licence body'));
    expect(text, isNot(contains('  licence body  ')));
  });
}
