import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:test/test.dart';

import 'fakes/fake_account_gateway.dart';

void main() {
  group('AppwriteUserPreferences', () {
    test('getAll starts empty', () async {
      final prefs = AppwriteUserPreferences.withGateway(FakeAccountGateway());

      expect(await prefs.getAll(), isEmpty);
    });

    test('update merges into the gateway rather than replacing it', () async {
      final gateway = FakeAccountGateway();
      final prefs = AppwriteUserPreferences.withGateway(gateway);

      await prefs.update(<String, dynamic>{'consent': true});
      await prefs.update(<String, dynamic>{'onboardingDismissed': true});

      expect(await prefs.getAll(), <String, dynamic>{
        'consent': true,
        'onboardingDismissed': true,
      });
    });

    test('update with a null value removes the key', () async {
      final gateway = FakeAccountGateway();
      final prefs = AppwriteUserPreferences.withGateway(gateway);
      await prefs.update(<String, dynamic>{'consent': true});

      await prefs.update(<String, dynamic>{'consent': null});

      expect(await prefs.getAll(), isEmpty);
    });

    test('the gateway itself only ever sees a full replacement, never a '
        'partial patch — the merge happens on this side', () async {
      final gateway = FakeAccountGateway()
        ..prefs = <String, dynamic>{'consent': true};
      final prefs = AppwriteUserPreferences.withGateway(gateway);

      await prefs.update(<String, dynamic>{'onboardingDismissed': true});

      expect(gateway.prefs, <String, dynamic>{
        'consent': true,
        'onboardingDismissed': true,
      });
    });
  });
}
