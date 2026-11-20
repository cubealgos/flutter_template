// Fixture data (HTTP statuses, JSON shapes of the OSV API) and fake-client
// callbacks; naming each status or silencing each empty no-op would only add
// noise to the tests.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/no_empty_block

import 'package:test/test.dart';
import 'package:tooling/src/advisory_severity.dart';
import 'package:tooling/src/cvss3.dart';

void main() {
  group('cvss3BaseScore', () {
    test('matches the CVSS v3.1 specification examples', () {
      expect(
        cvss3BaseScore('CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H'),
        9.8,
      );
      expect(
        cvss3BaseScore('CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H'),
        10.0,
      );
      expect(
        cvss3BaseScore('CVSS:3.1/AV:L/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:H'),
        7.8,
      );
      expect(
        cvss3BaseScore('CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:C/C:L/I:L/A:N'),
        6.1,
      );
      expect(
        cvss3BaseScore('CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:N'),
        0.0,
      );
    });

    test('rejects malformed and non-v3 vectors', () {
      expect(cvss3BaseScore('CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N'), isNull);
      expect(cvss3BaseScore('garbage'), isNull);
      expect(
        cvss3BaseScore('CVSS:3.1/AV:X/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H'),
        isNull,
      );
    });
  });

  group('assessSeverity', () {
    test('reads GitHub labels', () {
      for (final (label, expected) in [
        ('CRITICAL', AdvisorySeverity.critical),
        ('HIGH', AdvisorySeverity.high),
        ('MODERATE', AdvisorySeverity.medium),
        ('LOW', AdvisorySeverity.low),
      ]) {
        final a = assessSeverity({
          'database_specific': {'severity': label},
        });
        expect(a.severity, expected);
        expect(a.unrated, isFalse);
      }
    });

    test('the highest signal wins over a lower label', () {
      final a = assessSeverity({
        'severity': [
          {
            'type': 'CVSS_V3',
            'score': 'CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H',
          },
        ],
        'database_specific': {'severity': 'LOW'},
      });
      expect(a.severity, AdvisorySeverity.critical);
    });

    test('reads a label under affected[]', () {
      final a = assessSeverity({
        'affected': [
          {
            'ecosystem_specific': {'severity': 'HIGH'},
          },
        ],
      });
      expect(a.severity, AdvisorySeverity.high);
    });
  });

  group('assessSeverity unrated and thresholds', () {
    test('a CVSS v4-only advisory is unrated and counts as high', () {
      final a = assessSeverity({
        'severity': [
          {'type': 'CVSS_V4', 'score': 'CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N'},
        ],
      });
      expect(a.severity, AdvisorySeverity.high);
      expect(a.unrated, isTrue);
      expect(a.severity.blocksRelease, isTrue);
    });

    test('an advisory with nothing parseable is unrated high', () {
      expect(assessSeverity({}).unrated, isTrue);
      expect(
        assessSeverity({
          'database_specific': {'severity': 'WEIRD'},
        }).severity,
        AdvisorySeverity.high,
      );
    });

    test('medium and low do not block', () {
      expect(AdvisorySeverity.medium.blocksRelease, isFalse);
      expect(AdvisorySeverity.high.blocksRelease, isTrue);
    });
  });
}
