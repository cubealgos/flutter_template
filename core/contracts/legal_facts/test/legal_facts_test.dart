import 'package:legal_facts/legal_facts.dart';
import 'package:test/test.dart';

void main() {
  group('LegalFacts', () {
    test('every field is a non-empty placeholder', () {
      expect(LegalFacts.companyName, isNotEmpty);
      expect(LegalFacts.address, isNotEmpty);
      expect(LegalFacts.register, isNotEmpty);
      expect(LegalFacts.vatId, isNotEmpty);
      expect(LegalFacts.contactEmail, isNotEmpty);
      expect(LegalFacts.responsiblePerson, isNotEmpty);
      expect(LegalFacts.supervisoryAuthority, isNotEmpty);
      expect(LegalFacts.securityEmail, isNotEmpty);
    });

    test('contactEmail looks like an email address', () {
      expect(LegalFacts.contactEmail, contains('@'));
    });

    test('securityEmail looks like an email address, distinct from '
        'contactEmail', () {
      expect(LegalFacts.securityEmail, contains('@'));
      expect(LegalFacts.securityEmail, isNot(LegalFacts.contactEmail));
    });
  });
}
