import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite_adapters/src/account_gateway.dart';
import 'package:appwrite_adapters/src/appwrite_account_gateway.dart';
import 'package:appwrite_adapters/src/appwrite_auth_error_mapping.dart';
import 'package:auth/auth.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// The default set of what this adapter's Appwrite backend supports —
/// see this class's dartdoc for the passkey finding.
const AuthCapabilities _defaultAppwriteAuthCapabilities = AuthCapabilities(
  supportsOAuthApple: true,
  supportsOAuthGoogle: true,
);

/// The Appwrite `AppwriteException.code` `AppwriteAuthService.restoreSession`
/// treats as "no session to resume", not a failure — see that method's
/// dartdoc. Named locally, matching `appwrite_auth_error_mapping.dart`'s
/// convention, rather than `dart:io`'s `HttpStatus` (which doesn't compile
/// for web).
const int _unauthorizedStatusCode = 401;

/// The [AuthService] implementation backed by Appwrite's `Account` and
/// `Functions` services (via [AccountGateway]).
///
/// **Passkey finding:** as of the `appwrite`
/// 26.2.0 client SDK this adapter is built on, the `Account` class has no
/// passkey/WebAuthn methods at all (confirmed against its generated API
/// docs — no `createPasskey`/`updatePasskey`/anything WebAuthn-shaped, only
/// `createEmailToken`, `createMagicURLToken`, `createOAuth2Session`,
/// `createOAuth2Token`, `createAnonymousSession`, `createSession`,
/// `listIdentities`, `deleteIdentity`, `updatePrefs`, `deleteSession(s)`,
/// `get`). A public passkey feature request has been open on Appwrite's
/// GitHub since January 2024 with no shipped implementation as of this
/// writing. [signInWithPasskey] therefore always throws
/// [AuthUnsupportedError], and [capabilities] always reports
/// `supportsPasskeys: false` — there is no version check to make, because
/// no version of Appwrite this template could target has it.
///
/// **Session restore across app restarts**: [currentSession]
/// only reflects sessions this instance itself created via
/// [verifyEmailCode]/[signInWithOAuth]/[signInWithPasskey] — *until*
/// [restoreSession] is called, which asks
/// the backend directly (`AccountGateway.getCurrentUser`, i.e.
/// `Account.get`) whether a session already exists (e.g. one the
/// underlying `Client`'s cookie jar persisted from a previous app run) and
/// adopts it if so. A bootstrap/splash screen's controller calls this once,
/// before reading [currentSession].
///
/// **App Review demo account:** [signInWithReviewCode] executes
/// the `review_demo_sign_in` action of the `api` Appwrite Function
/// (`backend/appwrite/functions/api`) with a shared code and, on a
/// match, exchanges the token it returns for a real session via the same
/// `AccountGateway.createSessionFromToken` call [verifyEmailCode] already
/// uses. **Not**
/// an email+password session: an earlier version of this design used
/// `Account.createEmailPasswordSession` for one allow-listed account, but
/// that requires Appwrite's `email-password` auth method to stay enabled
/// project-wide — live-verified (on review) to be a real account-
/// takeover hole even for accounts nothing to do with the demo one (an
/// attacker pre-creates `victim@x` with a chosen password via the public
/// `Account.create` endpoint; `AppwriteAuthService.requestEmailCode`'s own
/// "Email-code existence finding" above means a legitimate later OTP
/// sign-up for that address silently lands in the attacker's pre-created
/// account). `backend/appwrite/tool/lib/src/provisioner.dart`'s `unusedAuthMethods` now
/// disables `email-password` (and `magic-url`/`invites`/`jwt`/`phone`)
/// project-wide on every provisioning run, which rules password sessions
/// out entirely — this Function-based path needs no auth method enabled
/// at all, since it never touches `Account`'s public sign-up/sign-in
/// surface. The Function's own `REVIEW_DEMO_USER_ID`/`REVIEW_DEMO_CODE`
/// variables (never the request) fix which account this can ever
/// authenticate as; see that Function's own dartdoc.
///
/// **`OAuth` and passkey sign-in cannot run headless** (they launch a
/// platform browser view / a native passkey prompt), so neither is
/// exercised by `backend/appwrite/tool/test/integration/` — see `test/` in this package
/// for the unit tests covering this class's own logic (capability gating,
/// error mapping, session-stream updates) against a fake [AccountGateway]
/// instead.
///
/// **Email-code existence finding (verified live against a real local
/// Appwrite 2.2.0 instance, then confirmed in Appwrite's own source —
/// `app/controllers/api/account.php`'s `createEmailToken` route):**
/// [requestEmailCode] looks the given email up by email first, *not* by
/// the `userId` it's called with — a repeat request for an
/// already-registered email returns a `Token` for that *existing*
/// account (`Token.userId` is the original account's ID, confirmed by
/// creating a user via the admin API and observing the client call's
/// response reuse that exact ID), silently ignoring the fresh
/// `ID.unique()` this method passes. So this one call already satisfies
/// [AuthService.requestEmailCode]'s "never reveals existence" contract
/// on its own, with nothing extra needed here — an earlier version of
/// this method assumed the opposite (that a duplicate email would error)
/// and masked a `user_already_exists`-shaped error that, it turns out,
/// Appwrite never actually throws for this case; removed once this was
/// verified. One narrow residual case genuinely does error: an email
/// already attached only to a linked OAuth identity (no separate
/// email/password account) throws `general_bad_request` — Appwrite's own
/// source comment calls this "prevent exposing existing accounts", but a
/// distinct error *is* itself a weak signal in that one case. Left
/// unmasked (see [requestEmailCode]'s own try/catch) — a real, Appwrite-
/// side edge case, not something this adapter can safely paper over.
class AppwriteAuthService implements AuthService {
  /// Creates a service backed by [client]. [client] is only used to build
  /// the default [AccountGateway] — see [AccountGateway] for the
  /// interface an app or test can swap in instead.
  AppwriteAuthService(
    Client client, {
    this.capabilities = _defaultAppwriteAuthCapabilities,
  }) : _gateway = AppwriteAccountGateway(client);

  /// Creates a service against a given [gateway] directly — for tests,
  /// bypassing the real Appwrite SDK (and the Flutter platform bindings
  /// some of its calls need) entirely.
  @visibleForTesting
  AppwriteAuthService.withGateway(
    AccountGateway gateway, {
    this.capabilities = _defaultAppwriteAuthCapabilities,
  }) : _gateway = gateway;

  @override
  final AuthCapabilities capabilities;

  final AccountGateway _gateway;
  final StreamController<AuthSession?> _sessionController =
      StreamController<AuthSession?>.broadcast();
  AuthSession? _currentSession;

  @override
  AuthSession? get currentSession => _currentSession;

  @override
  Stream<AuthSession?> get sessionChanges => _sessionController.stream;

  @override
  Future<AuthSession?> restoreSession() async {
    try {
      final user = await _gateway.getCurrentUser();
      final email = user.email.isEmpty ? null : user.email;

      return _applySession(AuthSession(userId: user.$id, email: email));
    } on AppwriteException catch (e) {
      // A 401 here means "no session to resume" - the expected, common
      // case on a fresh install - not a failure worth surfacing as an
      // error, and nothing here logs it. The browser itself still prints
      // "Failed to load resource ... 401" for the request; that line is
      // expected and harmless. It is not suppressed because the request
      // cannot be skipped safely: web OAuth (`createOAuth2Session`) leaves
      // the session in an API-domain cookie with no `cookieFallback`, so
      // "no stored fallback" does not prove "no session". Hiding the line
      // would need Appwrite's token-based web OAuth flow instead.
      if (e.code == _unauthorizedStatusCode) return null;
      throw mapAppwriteAuthError(e);
    }
  }

  @override
  Future<EmailCodeRequest> requestEmailCode(String email) async {
    if (!capabilities.supportsEmailCode) {
      throw const AuthUnsupportedError('Email code sign-in is disabled.');
    }

    try {
      // `ID.unique()` here is *not* "the new account's ID" - Appwrite's
      // own `createEmailToken` looks the given email up first and, if it
      // already belongs to an account, issues the token for that
      // account and ignores this ID entirely (verified live against
      // Appwrite 2.2.0's real response: `Token.userId` for a repeat email
      // comes back as the *original* account's ID, not a new one; and
      // confirmed in Appwrite's own source, `app/controllers/api/
      // account.php`'s `createEmailToken` route - "if the email address
      // has never been used, a new account is created using the
      // provided userId. Otherwise ... the user ID is ignored" - it does
      // `$dbForProject->findOne('users', [Query::equal('email', ...)])`
      // before ever looking at the given ID). So this one call already
      // returns the identical shape whether the account is new or
      // returning, with no special-casing needed here.
      final token = await _gateway.createEmailToken(
        userId: ID.unique(),
        email: email,
      );

      return EmailCodeRequest(userId: token.userId, email: email);
    } on AppwriteException catch (e) {
      // One narrow, real exception to "never reveals existence": if this
      // email is *not* a plain account but already belongs to a linked
      // OAuth identity, Appwrite's own route throws `general_bad_request`
      // rather than silently issuing a token — its own source comment
      // reads "prevent exposing existing accounts", but a distinct error
      // here is itself a (weak) signal. This is Appwrite's own design
      // choice in a genuinely rare case (an OAuth-only account never
      // linked to an email/password identity trying email-code sign-in);
      // not masked here, since it's not a case this adapter alone can
      // paper over cleanly - flagged as a known limitation.
      throw mapAppwriteAuthError(e);
    }
  }

  @override
  Future<AuthSession> verifyEmailCode(
    EmailCodeRequest request,
    String code,
  ) async {
    try {
      final session = await _gateway.createSessionFromToken(
        userId: request.userId,
        secret: code,
      );

      return _applySession(
        AuthSession(userId: session.userId, email: request.email),
      );
    } on AppwriteException catch (e) {
      throw mapAppwriteAuthError(e);
    }
  }

  @override
  Future<AuthSession> signInWithPasskey() async {
    // See this class's dartdoc for the passkey research finding.
    throw const AuthUnsupportedError(
      'Appwrite has no passkey/WebAuthn support as of the appwrite 26.2.0 '
      'client SDK.',
    );
  }

  @override
  Future<AuthSession> signInWithOAuth(OAuthProvider provider) async {
    if (!_supportsOAuth(provider)) {
      throw AuthUnsupportedError(
        'OAuth provider "${provider.name}" is disabled.',
      );
    }

    try {
      await _gateway.createOAuth2Session(_toAppwriteProvider(provider));
      final user = await _gateway.getCurrentUser();
      final email = user.email.isEmpty ? null : user.email;

      return _applySession(AuthSession(userId: user.$id, email: email));
    } on AppwriteException catch (e) {
      throw mapAppwriteAuthError(e);
    }
  }

  @override
  Future<AuthSession> signInWithReviewCode(String code) async {
    try {
      final responseBody = await _gateway.executeReviewDemoSignInFunction(code);
      final json = decodeFunctionResponse(responseBody);
      final session = await _gateway.createSessionFromToken(
        userId: json['userId'] as String,
        secret: json['secret'] as String,
      );

      return _applySession(AuthSession(userId: session.userId));
    } on AppwriteException catch (e) {
      // A wrong review code is the Function's own well-formed 401 (see
      // `AccountGateway.executeReviewDemoSignInFunction`'s dartdoc), not
      // one of Appwrite's own auth error types `mapAppwriteAuthError`
      // knows how to read `AppwriteException.type` for - narrowed here by
      // status code instead.
      if (e.code == _unauthorizedStatusCode) {
        throw AuthInvalidCodeError(e.message ?? 'Invalid review code.');
      }
      throw mapAppwriteAuthError(e);
    }
  }

  @override
  Future<void> signOut() async {
    if (_currentSession == null) return;

    try {
      await _gateway.deleteCurrentSession();
    } on AppwriteException catch (e) {
      throw mapAppwriteAuthError(e);
    }
    _clearSession();
  }

  @override
  Future<void> deleteAccount() async {
    _requireSession();

    try {
      final responseBody = await _gateway.executeDeleteAccountFunction();
      final json = decodeFunctionResponse(responseBody);
      final result = AccountDeletionResult.fromJson(json);
      if (!result.userDeleted) {
        throw AuthUnknownError(
          'delete_account ran but did not delete the user: $json',
        );
      }
    } on AppwriteException catch (e) {
      throw mapDeleteAccountError(e);
    }

    _clearSession();
  }

  @override
  Future<List<LinkedIdentity>> listIdentities() async {
    _requireSession();

    try {
      final identities = await _gateway.listIdentities();

      return identities.identities
          .map(
            (identity) => LinkedIdentity(
              id: identity.$id,
              provider: identity.provider,
              providerEmail: identity.providerEmail.isEmpty
                  ? null
                  : identity.providerEmail,
            ),
          )
          .toList();
    } on AppwriteException catch (e) {
      throw mapAppwriteAuthError(e);
    }
  }

  @override
  Future<void> unlinkIdentity(String identityId) async {
    _requireSession();

    try {
      await _gateway.deleteIdentity(identityId);
    } on AppwriteException catch (e) {
      throw mapAppwriteAuthError(e);
    }
  }

  bool _supportsOAuth(OAuthProvider provider) => switch (provider) {
    OAuthProvider.apple => capabilities.supportsOAuthApple,
    OAuthProvider.google => capabilities.supportsOAuthGoogle,
  };

  AuthSession _applySession(AuthSession session) {
    _currentSession = session;
    _sessionController.add(session);

    return session;
  }

  void _clearSession() {
    _currentSession = null;
    _sessionController.add(null);
  }

  void _requireSession() {
    if (_currentSession == null) {
      throw const AuthUnauthenticatedError('No current session.');
    }
  }
}

enums.OAuthProvider _toAppwriteProvider(OAuthProvider provider) =>
    switch (provider) {
      OAuthProvider.apple => enums.OAuthProvider.apple,
      OAuthProvider.google => enums.OAuthProvider.google,
    };
