import 'dart:async';

import 'package:auth/src/auth_capabilities.dart';
import 'package:auth/src/auth_error.dart';
import 'package:auth/src/auth_service.dart';
import 'package:auth/src/auth_session.dart';
import 'package:auth/src/email_code_request.dart';
import 'package:auth/src/linked_identity.dart';
import 'package:auth/src/oauth_provider.dart';

/// A pending email code, tracked internally by [FakeAuthService].
class _PendingEmailCode {
  _PendingEmailCode({required this.email, required this.code});

  final String email;
  final String code;
}

/// An in-memory, deterministic [AuthService] for screens and tests — no
/// network calls, no real codes sent anywhere.
///
/// Every email code this fake issues is [fixedEmailCode] — a test drives
/// the verify step by entering that literal string, rather than needing to
/// intercept a randomly generated one. State (sessions, pending codes,
/// linked identities) lives only in memory and resets with a new instance.
class FakeAuthService implements AuthService {
  /// Creates a fake service. [capabilities] defaults to every flow turned
  /// on, unlike a real backend's likely defaults, so a screen test can
  /// exercise every button without special-casing the fake.
  FakeAuthService({
    AuthSession? persistedSession,
    this.reviewDemoCode,
    this.ownedTeamNames,
    this.onAccountDeleted,
    this.capabilities = const AuthCapabilities(
      supportsPasskeys: true,
      supportsOAuthApple: true,
      supportsOAuthGoogle: true,
    ),
  })
    // An initializing formal (`this._persistedSession`) would make the
    // private field name itself the external parameter name, which is not a
    // callable identifier outside this library — the public parameter name
    // `persistedSession` is deliberate API surface, kept distinct from the
    // private field it seeds. This is a core `package:lints` diagnostic
    // (not a solid_lints one), so this ignore is intentionally
    // unnamespaced — see `core/architecture/mvc/lib/src/view_controller.dart` for
    // the same pattern.
    // ignore: prefer_initializing_formals
    : _persistedSession = persistedSession;

  /// The code [requestEmailCode] always issues, and the only code
  /// [verifyEmailCode] accepts.
  static const String fixedEmailCode = '123456';

  /// The fixed session identity [signInWithReviewCode] starts when
  /// [reviewDemoCode] matches — the fake-backend analogue of the real
  /// backend's admin-seeded demo account.
  static const String reviewDemoUserId = 'review-demo-user';

  /// The fixed code a fake-backend build's `AppConfig.reviewDemoEnabled`
  /// wiring passes as [reviewDemoCode] — the fake-backend analogue of
  /// [fixedEmailCode], for the same reason: a review build run against the
  /// fake backend needs a reviewer-enterable, publicly documented
  /// credential (see `apps/app/README.md`'s "App Review demo access"
  /// section), not a real secret.
  static const String fixedReviewDemoCode = 'REVIEW-123456';

  /// The App Review demo code this fake accepts for [signInWithReviewCode]
  /// — mirrors `AppConfig.reviewDemoEnabled`/the real backend's
  /// `REVIEW_DEMO_CODE` function variable. Null (the default) rejects
  /// every attempt with [AuthUnsupportedError], modeling a build with no
  /// demo account configured.
  final String? reviewDemoCode;

  /// Asks the fake tenancy backend which teams a user owns, so
  /// [deleteAccount] mirrors the real backend's refusal: a
  /// non-empty answer makes it throw [AuthOwnsTeamsError]. `package:auth`
  /// does not know teams, so the app wires this to its fake team backend;
  /// null (the default) means no teams, and deletion is never refused.
  final Future<List<String>> Function(String userId)? ownedTeamNames;

  /// Called with the user's ID after [deleteAccount] succeeded, so a fake
  /// tenancy backend can drop the user's memberships (as deleting an
  /// Appwrite user does) while keeping the team history.
  final Future<void> Function(String userId)? onAccountDeleted;

  /// What [restoreSession] resumes the first time it's called, modelling a
  /// session a previous (now-gone) instance would have persisted — a fresh
  /// `FakeAuthService` has no real persistence of its own, so a test that
  /// wants to exercise "app restart with an existing session" passes this
  /// to the constructor instead.
  AuthSession? _persistedSession;

  @override
  final AuthCapabilities capabilities;

  final StreamController<AuthSession?> _sessionController =
      StreamController<AuthSession?>.broadcast();
  final Map<String, String> _userIdByEmail = <String, String>{};
  final Map<String, _PendingEmailCode> _pendingCodeByUserId =
      <String, _PendingEmailCode>{};
  final Map<String, List<LinkedIdentity>> _identitiesByUserId =
      <String, List<LinkedIdentity>>{};
  AuthSession? _currentSession;
  int _userSequence = 0;

  @override
  AuthSession? get currentSession => _currentSession;

  @override
  Stream<AuthSession?> get sessionChanges => _sessionController.stream;

  @override
  Future<AuthSession?> restoreSession() async {
    if (_currentSession != null) return _currentSession;
    final persisted = _persistedSession;
    if (persisted == null) return null;

    // Only ever resumed once — a real backend's persisted session is
    // consumed by the platform, not re-offered on every call.
    _persistedSession = null;

    return _startSession(persisted);
  }

  @override
  Future<EmailCodeRequest> requestEmailCode(String email) async {
    if (!capabilities.supportsEmailCode) {
      throw const AuthUnsupportedError(
        'This FakeAuthService was configured with supportsEmailCode: false.',
      );
    }

    // Same lookup-or-create shape whether `email` was already registered
    // or not - the returned EmailCodeRequest never differs by that fact,
    // matching AuthService.requestEmailCode's non-revealing contract.
    final userId = _userIdByEmail[email] ??= _nextUserId();
    _pendingCodeByUserId[userId] = _PendingEmailCode(
      email: email,
      code: fixedEmailCode,
    );

    return EmailCodeRequest(userId: userId, email: email);
  }

  @override
  Future<AuthSession> verifyEmailCode(
    EmailCodeRequest request,
    String code,
  ) async {
    final pending = _pendingCodeByUserId[request.userId];
    if (pending == null || pending.email != request.email) {
      throw const AuthInvalidCodeError(
        'No pending email code for this request.',
      );
    }
    if (pending.code != code) {
      throw const AuthInvalidCodeError('Incorrect code.');
    }

    _pendingCodeByUserId.remove(request.userId);

    return _startSession(
      AuthSession(userId: request.userId, email: request.email),
    );
  }

  @override
  Future<AuthSession> signInWithPasskey() async {
    if (!capabilities.supportsPasskeys) {
      throw const AuthUnsupportedError(
        'This FakeAuthService was configured with supportsPasskeys: false.',
      );
    }

    return _startSession(AuthSession(userId: _nextUserId()));
  }

  @override
  Future<AuthSession> signInWithOAuth(OAuthProvider provider) async {
    final supported = switch (provider) {
      OAuthProvider.apple => capabilities.supportsOAuthApple,
      OAuthProvider.google => capabilities.supportsOAuthGoogle,
    };
    if (!supported) {
      throw AuthUnsupportedError(
        'This FakeAuthService was configured without OAuth provider '
        '"${provider.name}".',
      );
    }

    final userId = _nextUserId();
    final email = '${provider.name}-user@example.com';
    _identitiesByUserId[userId] = <LinkedIdentity>[
      LinkedIdentity(
        id: 'identity-$userId',
        provider: provider.name,
        providerEmail: email,
      ),
    ];

    return _startSession(AuthSession(userId: userId, email: email));
  }

  @override
  Future<AuthSession> signInWithReviewCode(String code) async {
    final configuredCode = reviewDemoCode;
    if (configuredCode == null) {
      throw const AuthUnsupportedError(
        'This FakeAuthService was created with no reviewDemoCode.',
      );
    }
    if (code != configuredCode) {
      throw const AuthInvalidCodeError('Invalid review code.');
    }

    return _startSession(const AuthSession(userId: reviewDemoUserId));
  }

  @override
  Future<void> signOut() async {
    if (_currentSession == null) return;
    _currentSession = null;
    _sessionController.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    final session = _requireSession();
    final owned = await ownedTeamNames?.call(session.userId) ?? <String>[];
    if (owned.isNotEmpty) {
      throw AuthOwnsTeamsError(
        'The account owns teams: ${owned.join(', ')}. Transfer ownership or '
        'delete them first.',
        teamNames: owned,
      );
    }
    _identitiesByUserId.remove(session.userId);
    _pendingCodeByUserId.remove(session.userId);
    _userIdByEmail.removeWhere((_, userId) => userId == session.userId);
    _currentSession = null;
    _sessionController.add(null);
    await onAccountDeleted?.call(session.userId);
  }

  @override
  Future<List<LinkedIdentity>> listIdentities() async {
    final session = _requireSession();

    return List<LinkedIdentity>.unmodifiable(
      _identitiesByUserId[session.userId] ?? const <LinkedIdentity>[],
    );
  }

  @override
  Future<void> unlinkIdentity(String identityId) async {
    final session = _requireSession();
    _identitiesByUserId[session.userId]?.removeWhere(
      (identity) => identity.id == identityId,
    );
  }

  AuthSession _startSession(AuthSession session) {
    _currentSession = session;
    _sessionController.add(session);

    return session;
  }

  AuthSession _requireSession() {
    final session = _currentSession;
    if (session == null) {
      throw const AuthUnauthenticatedError('No current session.');
    }

    return session;
  }

  String _nextUserId() => 'fake-user-${_userSequence++}';
}
