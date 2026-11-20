import 'package:test/test.dart';
import 'package:tooling/src/rename_identity.dart';

void main() {
  group('isValidSnakeCaseName', () {
    test('accepts lowercase snake_case', () {
      expect(isValidSnakeCaseName('acme_notes'), isTrue);
      expect(isValidSnakeCaseName('a'), isTrue);
      expect(isValidSnakeCaseName('app2'), isTrue);
    });

    test('rejects anything not lowercase snake_case', () {
      expect(isValidSnakeCaseName('Acme'), isFalse);
      expect(isValidSnakeCaseName('acme-notes'), isFalse);
      expect(isValidSnakeCaseName('acme notes'), isFalse);
      expect(isValidSnakeCaseName('2acme'), isFalse);
      expect(isValidSnakeCaseName(''), isFalse);
    });
  });

  group('isValidReverseDomainOrg', () {
    test('accepts a two-or-more-segment reverse domain', () {
      expect(isValidReverseDomainOrg('de.example'), isTrue);
      expect(isValidReverseDomainOrg('com.example.sub'), isTrue);
    });

    test('rejects a single segment or invalid characters', () {
      expect(isValidReverseDomainOrg('example'), isFalse);
      expect(isValidReverseDomainOrg('de.Example'), isFalse);
      expect(isValidReverseDomainOrg('de.example.'), isFalse);
      expect(isValidReverseDomainOrg('.de.example'), isFalse);
      expect(isValidReverseDomainOrg('de.2example'), isFalse);
    });
  });

  group('RenameRequest', () {
    test('derives applicationId and workspaceName', () {
      const request = RenameRequest(
        name: 'acme_notes',
        org: 'de.example',
        display: 'Acme Notes',
      );

      expect(request.applicationId, 'de.example.acme_notes');
      expect(request.workspaceName, 'acme_notes_workspace');
    });
  });

  group('OldIdentity', () {
    const identity = OldIdentity(
      workspaceName: 'flutter_template_workspace',
      appPackageName: 'app',
      applicationId: 'com.example.app',
      displayName: 'flutter_template',
      macCopyright: 'Copyright © 2026 com.example. All rights reserved.',
      windowsCopyright: 'Copyright (C) 2026 com.example. All rights reserved.',
    );

    test('derives org from the last segment of applicationId', () {
      expect(identity.org, 'com.example');
    });

    test('derives templateToken by stripping the _workspace suffix', () {
      expect(identity.templateToken, 'flutter_template');
    });

    test('templateToken returns the whole name when there is no suffix', () {
      const noSuffix = OldIdentity(
        workspaceName: 'flutter_template',
        appPackageName: 'app',
        applicationId: 'com.example.app',
        displayName: 'flutter_template',
        macCopyright: '',
        windowsCopyright: '',
      );

      expect(noSuffix.templateToken, 'flutter_template');
    });

    test('rewriteCopyright swaps only the org, keeping year and phrasing', () {
      expect(
        identity.rewriteCopyright(identity.macCopyright, 'de.example'),
        'Copyright © 2026 de.example. All rights reserved.',
      );
      expect(
        identity.rewriteCopyright(identity.windowsCopyright, 'de.example'),
        'Copyright (C) 2026 de.example. All rights reserved.',
      );
    });

    test('org derivation falls back to the whole id with no dot', () {
      const noDot = OldIdentity(
        workspaceName: 'flutter_template_workspace',
        appPackageName: 'app',
        applicationId: 'standalone',
        displayName: 'flutter_template',
        macCopyright: '',
        windowsCopyright: '',
      );

      expect(noDot.org, 'standalone');
    });
  });

  group('OldIdentity.leftoverSearchTerms', () {
    const identity = OldIdentity(
      workspaceName: 'flutter_template_workspace',
      appPackageName: 'app',
      applicationId: 'com.example.app',
      displayName: 'flutter_template',
      macCopyright: '',
      windowsCopyright: '',
    );

    test('covers the token, its space variant and the org', () {
      expect(identity.leftoverSearchTerms, {
        'flutter_template',
        'flutter template',
        'com.example',
      });
    });

    test('drops blank terms', () {
      const blankDisplay = OldIdentity(
        workspaceName: 'flutter_template_workspace',
        appPackageName: 'app',
        applicationId: 'standalone',
        displayName: '  ',
        macCopyright: '',
        windowsCopyright: '',
      );

      expect(blankDisplay.leftoverSearchTerms, {
        'flutter_template',
        'flutter template',
        'standalone',
      });
    });
  });
}
