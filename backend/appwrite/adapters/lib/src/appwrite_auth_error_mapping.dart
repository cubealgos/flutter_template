import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:auth/auth.dart';

/// The Appwrite `AppwriteException.code`s that map to a specific
/// [AuthError] below, rather than falling through to [AuthUnknownError].
const int _tooManyRequestsStatusCode = 429;
const int _unauthorizedStatusCode = 401;

/// Maps an error caught from an `AccountGateway` call to a typed
/// [AuthError].
///
/// Appwrite's own error catalog (`AppwriteException.type`) is large and
/// only loosely documented; this maps the handful of cases this template's
/// screens actually need to tell apart (an expired/wrong code, a rate
/// limit, no session) by HTTP status first — more stable across Appwrite
/// versions than matching every possible `type` string — and only inspects
/// `type` for the one case status code alone can't distinguish (an
/// invalid vs. an expired token both come back as 401). Anything else
/// becomes [AuthUnknownError] rather than a wrong specific guess.
AuthError mapAppwriteAuthError(Object error, {String? contextMessage}) {
  if (error is! AppwriteException) {
    return AuthUnknownError(contextMessage ?? error.toString(), cause: error);
  }

  final message = error.message ?? contextMessage ?? 'Appwrite error.';

  return switch (error.code) {
    _tooManyRequestsStatusCode => AuthRateLimitedError(message),
    _unauthorizedStatusCode => _mapUnauthorized(error, message),
    _ => AuthUnknownError(message, cause: error),
  };
}

/// Narrows a 401 into the specific case it represents — an invalid or
/// expired code, or genuinely no session — by inspecting
/// [AppwriteException.type], the one thing the status code alone can't
/// distinguish.
AuthError _mapUnauthorized(AppwriteException error, String message) {
  final type = error.type ?? '';
  if (type.contains('expired')) return AuthCodeExpiredError(message);
  if (type.contains('token') || type.contains('credentials')) {
    return AuthInvalidCodeError(message);
  }

  return AuthUnauthenticatedError(message);
}

const int _conflictStatusCode = 409;

/// The wire `error.code` the `delete_account` action answers with when the
/// caller still owns a team (`ownsTeamsErrorCode` in the `api` Function).
const String _ownsTeamsCode = 'owns_teams';

/// Maps an error caught from the `delete_account` call: the action's own
/// refusal because the caller owns teams becomes [AuthOwnsTeamsError]
/// (carrying the team names), anything else goes through
/// [mapAppwriteAuthError].
///
/// `ApiClient.call` reports an action's failure as an [AppwriteException]
/// whose message is `"<action> returned <status>: <json body>"`; the body is
/// read from it here.
AuthError mapDeleteAccountError(AppwriteException error) {
  if (error.code == _conflictStatusCode) {
    final ownsTeams = _ownsTeamsFrom(error.message ?? '');
    if (ownsTeams != null) return ownsTeams;
  }

  return mapAppwriteAuthError(error);
}

/// The [AuthOwnsTeamsError] in an `ApiClient` failure [message], or null if
/// its JSON body is not the `owns_teams` refusal.
AuthOwnsTeamsError? _ownsTeamsFrom(String message) {
  final brace = message.indexOf('{');
  if (brace < 0) return null;
  final Object? decoded;
  try {
    decoded = jsonDecode(message.substring(brace));
  } on FormatException {
    return null;
  }
  final body = decoded is Map ? decoded['error'] : null;
  if (body is! Map || body['code'] != _ownsTeamsCode) return null;

  return AuthOwnsTeamsError(
    body['message'] as String? ?? 'The account owns teams.',
    teamNames: <String>[
      for (final name in body['teams'] as List<dynamic>? ?? <dynamic>[])
        '$name',
    ],
  );
}
