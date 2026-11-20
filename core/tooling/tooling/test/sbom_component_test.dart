import 'package:test/test.dart';
import 'package:tooling/src/sbom_component.dart';

void main() {
  group('SbomLicence', () {
    test('spdx() emits an id', () {
      expect(const SbomLicence.spdx('MIT').toJson(), {
        'license': {'id': 'MIT'},
      });
    });

    test('freeText() emits a name', () {
      expect(const SbomLicence.freeText('Some Custom Licence').toJson(), {
        'license': {'name': 'Some Custom Licence'},
      });
    });
  });

  group('SbomComponent', () {
    test('toJson() includes required fields, bom-ref and purl', () {
      const component = SbomComponent(
        type: 'library',
        name: 'http',
        version: '1.2.3',
        purl: 'pkg:pub/http@1.2.3',
      );

      final json = component.toJson();

      expect(json['type'], 'library');
      expect(json['name'], 'http');
      expect(json['version'], '1.2.3');
      expect(json['purl'], 'pkg:pub/http@1.2.3');
      expect(json['bom-ref'], 'pkg:pub/http@1.2.3');
      expect(json.containsKey('hashes'), isFalse);
      expect(json.containsKey('licenses'), isFalse);
    });

    test('toJson() includes hashes only when sha256 is set', () {
      const component = SbomComponent(
        type: 'library',
        name: 'http',
        version: '1.2.3',
        purl: 'pkg:pub/http@1.2.3',
        sha256: 'abc123',
      );

      expect(component.toJson()['hashes'], [
        {'alg': 'SHA-256', 'content': 'abc123'},
      ]);
    });

    test('toJson() includes licenses only when non-empty', () {
      const component = SbomComponent(
        type: 'library',
        name: 'http',
        version: '1.2.3',
        purl: 'pkg:pub/http@1.2.3',
        licences: [SbomLicence.spdx('MIT')],
      );

      expect(component.toJson()['licenses'], [
        {
          'license': {'id': 'MIT'},
        },
      ]);
    });
  });
}
