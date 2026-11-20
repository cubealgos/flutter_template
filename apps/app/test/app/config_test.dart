import 'package:app/app/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('every feature switch defaults to off', () {
      const config = AppConfig();

      expect(config.consentSheet, isFalse);
      expect(config.passkeys, isFalse);
      expect(config.socialLoginApple, isFalse);
      expect(config.socialLoginGoogle, isFalse);
      expect(config.paywall, isFalse);
      expect(config.accessibilityStatement, isFalse);
    });

    test('legal facts default to obvious placeholders', () {
      const config = AppConfig();

      expect(config.legalCompanyName, 'Example GmbH');
      expect(config.legalContactEmail, 'legal@example.com');
    });

    test('enabling Google social login without Apple violates App Store '
        'guideline 4.8', () {
      expect(
        () => AppConfig(socialLoginGoogle: true),
        throwsA(isA<AssertionError>()),
      );
    });

    test('enabling Google alongside Apple is allowed', () {
      expect(
        () => const AppConfig(socialLoginApple: true, socialLoginGoogle: true),
        returnsNormally,
      );
    });
  });
}
