import 'package:appwrite/appwrite.dart';
import 'package:data/data.dart';

/// The HTTP status Appwrite returns for "no such row/file".
const int _notFoundStatusCode = 404;

/// The HTTP status Appwrite returns for "no current session".
const int _unauthorizedStatusCode = 401;

/// The HTTP status Appwrite returns for "session exists, but isn't allowed
/// to touch this resource".
const int _forbiddenStatusCode = 403;

/// The HTTP status Appwrite returns for "this row already exists" (a taken
/// ID or a unique-index violation).
const int _conflictStatusCode = 409;

/// Maps an error caught from a `TablesDB`/`Storage`/`Account` call to a
/// typed [DataError] — see `mapAppwriteAuthError`'s dartdoc for why this
/// maps by HTTP status rather than Appwrite's much larger `type` catalog.
DataError mapAppwriteDataError(Object error, {String? contextMessage}) {
  if (error is! AppwriteException) {
    return DataUnknownError(contextMessage ?? error.toString(), cause: error);
  }

  final message = error.message ?? contextMessage ?? 'Appwrite error.';

  return switch (error.code) {
    _notFoundStatusCode => DataNotFoundError(message),
    _unauthorizedStatusCode => DataUnauthenticatedError(message),
    _forbiddenStatusCode => DataPermissionError(message),
    _conflictStatusCode => DataConflictError(message),
    _ => DataUnknownError(message, cause: error),
  };
}
