import 'package:test/test.dart';
import 'package:tooling/src/licence_policy.dart';
import 'package:tooling/src/pub_dev_licence_client.dart';

void main() {
  group('PackageLicences.spdxCandidates', () {
    test('maps known pub.dev tags to canonical SPDX ids', () {
      const licences = PackageLicences([
        'bsd-3-clause',
        'fsf-libre',
        'osi-approved',
      ]);

      expect(licences.spdxCandidates, ['BSD-3-Clause']);
      expect(licences.unrecognisedTags, isEmpty);
    });

    test('aliases python-2.0 to PSF-2.0 per the policy document', () {
      const licences = PackageLicences(['python-2.0']);

      expect(licences.spdxCandidates, ['PSF-2.0']);
    });

    test('carries multiple candidates for a dual-licensed package', () {
      const licences = PackageLicences([
        'bsd-3-clause',
        'mit',
        'fsf-libre',
        'osi-approved',
      ]);

      expect(licences.spdxCandidates, ['BSD-3-Clause', 'MIT']);
    });

    test('an unrecognised tag is neither a candidate nor silently dropped', () {
      const licences = PackageLicences(['some-future-spdx-id']);

      expect(licences.spdxCandidates, isEmpty);
      expect(licences.unrecognisedTags, ['some-future-spdx-id']);
    });

    test(
      'license:unknown is a badge, not a candidate or an unrecognised tag',
      () {
        const licences = PackageLicences(['unknown']);

        expect(licences.spdxCandidates, isEmpty);
        expect(licences.unrecognisedTags, isEmpty);
        expect(licences.isEmpty, isFalse);
      },
    );

    test('no license: tags at all reports isEmpty', () {
      expect(const PackageLicences([]).isEmpty, isTrue);
    });
  });

  test('every allowed licence is absent from the denied set', () {
    expect(allowedLicences.intersection(deniedLicences), isEmpty);
  });

  test('MPL-2.0 is deliberately on neither list', () {
    expect(allowedLicences.contains(mplLicence), isFalse);
    expect(deniedLicences.contains(mplLicence), isFalse);
  });

  test('the GPL family denies both -only and -or-later variants', () {
    expect(deniedLicences, containsAll(['GPL-3.0-only', 'GPL-3.0-or-later']));
  });
}
