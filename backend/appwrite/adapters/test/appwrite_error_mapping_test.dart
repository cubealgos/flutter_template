import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:test/test.dart';

const int _tooManyRequestsStatusCode = 429;
const int _unauthorizedStatusCode = 401;
const int _forbiddenStatusCode = 403;
const int _notFoundStatusCode = 404;
const int _serverErrorStatusCode = 500;

const int _conflictStatusCode = 409;

void main() {
  group('mapAppwriteAuthError', () {
    test('maps 429 to AuthRateLimitedError', () {
      final error = AppwriteException(
        'Too many requests',
        _tooManyRequestsStatusCode,
        'general_rate_limit',
      );

      expect(mapAppwriteAuthError(error), isA<AuthRateLimitedError>());
    });

    test('maps a 401 expired token to AuthCodeExpiredError', () {
      final error = AppwriteException(
        'Expired',
        _unauthorizedStatusCode,
        'user_token_expired',
      );

      expect(mapAppwriteAuthError(error), isA<AuthCodeExpiredError>());
    });

    test('maps a 401 invalid token to AuthInvalidCodeError', () {
      final error = AppwriteException(
        'Invalid',
        _unauthorizedStatusCode,
        'user_invalid_token',
      );

      expect(mapAppwriteAuthError(error), isA<AuthInvalidCodeError>());
    });

    test('maps a plain 401 to AuthUnauthenticatedError', () {
      final error = AppwriteException(
        'No session',
        _unauthorizedStatusCode,
        'general_unauthorized',
      );

      expect(mapAppwriteAuthError(error), isA<AuthUnauthenticatedError>());
    });

    test('maps anything else to AuthUnknownError', () {
      final error = AppwriteException(
        'Boom',
        _serverErrorStatusCode,
        'general_server_error',
      );

      expect(mapAppwriteAuthError(error), isA<AuthUnknownError>());
    });

    test('maps a non-AppwriteException to AuthUnknownError', () {
      expect(
        mapAppwriteAuthError(StateError('offline')),
        isA<AuthUnknownError>(),
      );
    });
  });

  group('mapAppwriteDataError', () {
    test('maps 404 to DataNotFoundError', () {
      final error = AppwriteException(
        'Not found',
        _notFoundStatusCode,
        'document_not_found',
      );

      expect(mapAppwriteDataError(error), isA<DataNotFoundError>());
    });

    test('maps 401 to DataUnauthenticatedError', () {
      final error = AppwriteException(
        'No session',
        _unauthorizedStatusCode,
        'general_unauthorized',
      );

      expect(mapAppwriteDataError(error), isA<DataUnauthenticatedError>());
    });

    test('maps 403 to DataPermissionError', () {
      final error = AppwriteException(
        'Forbidden',
        _forbiddenStatusCode,
        'general_unauthorized_scope',
      );

      expect(mapAppwriteDataError(error), isA<DataPermissionError>());
    });

    test('maps 409 (a taken ID or a unique-index violation) to '
        'DataConflictError', () {
      final error = AppwriteException(
        'Exists',
        _conflictStatusCode,
        'row_already_exists',
      );

      expect(mapAppwriteDataError(error), isA<DataConflictError>());
    });

    test('maps anything else to DataUnknownError', () {
      final error = AppwriteException(
        'Boom',
        _serverErrorStatusCode,
        'general_server_error',
      );

      expect(mapAppwriteDataError(error), isA<DataUnknownError>());
    });
  });
}
