import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('AccountDeletionResult', () {
    test('round-trips through JSON', () {
      final result = AccountDeletionResult(
        userId: 'user-1',
        deletedAt: DateTime.utc(2026, 9, 23, 12),
        userDeleted: true,
        removedRows: const <String, int>{'profiles': 1},
        removedFiles: const <String, int>{'avatars': 2},
      );

      final restored = AccountDeletionResult.fromJson(result.toJson());

      expect(restored, result);
    });

    test('defaults removedRows and removedFiles to empty maps', () {
      final result = AccountDeletionResult(
        userId: 'user-1',
        deletedAt: DateTime.utc(2026, 9, 23, 12),
        userDeleted: false,
      );

      expect(result.removedRows, isEmpty);
      expect(result.removedFiles, isEmpty);
    });
  });
}
