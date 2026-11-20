import 'package:data/data.dart';

/// Throws [DataConflictError] unless [expected] equals the row's [actual]
/// version (`$updatedAt`): the check `AppwriteDocumentRepository.update`
/// makes for an `expectedVersion`. Kept separate so it is unit-testable
/// without a network.
void requireVersion(
  String id, {
  required String expected,
  required String actual,
}) {
  if (expected != actual) {
    throw DataConflictError(
      'Document "$id" changed since version $expected (now $actual).',
    );
  }
}
