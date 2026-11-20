import 'package:data/data.dart';
import 'package:test/test.dart';

void main() {
  group('FakeUserPreferences', () {
    test('getAll starts empty', () async {
      final prefs = FakeUserPreferences();

      expect(await prefs.getAll(), isEmpty);
    });

    test('update merges keys without clobbering others', () async {
      final prefs = FakeUserPreferences();

      await prefs.update(<String, dynamic>{'consent': true});
      await prefs.update(<String, dynamic>{'onboardingDismissed': true});

      expect(await prefs.getAll(), <String, dynamic>{
        'consent': true,
        'onboardingDismissed': true,
      });
    });

    test('update with a null value removes the key', () async {
      final prefs = FakeUserPreferences();
      await prefs.update(<String, dynamic>{'consent': true});

      await prefs.update(<String, dynamic>{'consent': null});

      expect(await prefs.getAll(), isEmpty);
    });

    test('every method throws DataUnauthenticatedError when signed out', () {
      final prefs = FakeUserPreferences(authenticated: false);

      expect(prefs.getAll, throwsA(isA<DataUnauthenticatedError>()));
      expect(
        () => prefs.update(<String, dynamic>{'a': 1}),
        throwsA(isA<DataUnauthenticatedError>()),
      );
    });
  });
}
