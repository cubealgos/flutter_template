import 'package:jaspr/server.dart' show Jaspr;
import 'package:jaspr_test/server_test.dart';
import 'package:legal_facts/legal_facts.dart';
import 'package:website/app.dart';

/// Keeps the website's legal pages (`lib/src/pages/impressum_page.dart`,
/// `datenschutz_page.dart`) quoting the single-source placeholder facts in
/// `package:legal_facts` (`core/contracts/legal_facts`) — the
/// same source `apps/app/lib/app/config.dart`'s `AppConfig` defaults its
/// `legal*` fields from. Reading `LegalFacts` directly (not `AppConfig`)
/// keeps this Flutter-free site's own test suite Flutter-free too — this test
/// used to import the Flutter `app` package just to reach the same
/// constants. A drift between the rendered page and `LegalFacts` fails
/// here instead of shipping quietly.
const _httpOk = 200;

void main() {
  Jaspr.initializeApp();

  // Every legal page (Impressum and Datenschutz alike) states who the
  // controller/provider is and how to reach them; only the Impressum
  // additionally states the commercial-register and VAT facts (a
  // Datenschutzerklärung has no legal reason to repeat those).
  const commonFields = [
    LegalFacts.companyName,
    LegalFacts.address,
    LegalFacts.contactEmail,
  ];
  const impressumOnlyFields = [
    LegalFacts.register,
    LegalFacts.vatId,
    LegalFacts.responsiblePerson,
  ];

  final legalPaths = [
    '/impressum',
    '/datenschutz',
    '/de/impressum',
    '/de/datenschutz',
  ];

  for (final path in legalPaths) {
    testServer("the legal page at $path quotes LegalFacts' placeholder "
        'facts', (tester) async {
      tester.pumpComponent(const App());
      final response = await tester.request(path);

      expect(response.statusCode, _httpOk);
      final body = response.body;

      for (final value in commonFields) {
        expect(
          body,
          contains(value),
          reason: 'expected $path to quote LegalFacts\' "$value"',
        );
      }
      if (path.endsWith('impressum')) {
        for (final value in impressumOnlyFields) {
          expect(
            body,
            contains(value),
            reason: 'expected $path to quote LegalFacts\' "$value"',
          );
        }
      }
    });
  }

  testServer("the Datenschutz pages quote LegalFacts' supervisory authority", (
    tester,
  ) async {
    tester.pumpComponent(const App());
    for (final path in ['/datenschutz', '/de/datenschutz']) {
      final response = await tester.request(path);
      expect(
        response.body,
        contains(LegalFacts.supervisoryAuthority),
        reason: 'expected $path to quote the supervisory authority',
      );
    }
  });

  testServer('every legal page carries the "template text" banner', (
    tester,
  ) async {
    tester.pumpComponent(const App());
    for (final path in legalPaths) {
      final response = await tester.request(path);
      expect(
        response.body,
        contains('legal-template-notice'),
        reason: 'expected $path to render the template-text banner',
      );
    }
  });
}
