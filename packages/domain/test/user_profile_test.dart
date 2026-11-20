import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('UserProfile', () {
    test('round-trips through JSON', () {
      const profile = UserProfile(userId: 'user-1', displayName: 'Alex');

      final restored = UserProfile.fromJson(profile.toJson());

      expect(restored, profile);
    });
  });
}
