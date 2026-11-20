import 'package:auth/src/auth_capabilities.dart';
import 'package:auth/src/auth_error.dart';
import 'package:auth/src/auth_session.dart';
import 'package:auth/src/email_code_request.dart';
import 'package:auth/src/linked_identity.dart';
import 'package:auth/src/oauth_provider.dart';

/// A backend-agnostic authentication service.
///
/// `backend/appwrite/adapters`'s `AppwriteAuthService` is the template's
/// default implementation; `FakeAuthService` is an in-memory one for
/// screens and tests. Every method throws a subtype of [AuthError] on
/// failure — see that class's dartdoc.
///
/// This template deliberately covers email OTP as its one code-based
/// sign-in flow, not magic links too: both solve the same "no passwords"
/// requirement from the plan's "Default screens" section, and offering
/// just one keeps this interface small (per the issue's "keep it small and
/// honest" instruction) and works without deep-link setup on every
/// platform this template targets. An app that wants a magic link instead
/// adds it to its own copy of this interface after cloning.
abstract class AuthService {
  /// What this backend actually supports — a screen reads this to decide
  /// which sign-in buttons to show.
  AuthCapabilities get capabilities;

  /// The current session, or null if signed out. Reflects the same value
  /// [sessionChanges] would emit right now, without waiting for the next
  /// event.
  AuthSession? get currentSession;

  /// Emits the current session (and null on sign-out) every time it
  /// changes through one of this interface's own methods. Does not replay
  /// past events to a new subscriber — read [currentSession] for the value
  /// at subscription time, then listen here for later changes. A
  /// bootstrap/splash screen (see the plan) reads [currentSession] to
  /// resolve its initial route, then listens here for sign-out.
  Stream<AuthSession?> get sessionChanges;

  /// Attempts to resume a session that already exists (e.g. one the
  /// platform persisted from a previous app run) without starting a new
  /// one — the second step of the plan's "Bootstrap/splash" default screen
  /// ("Resolves the minimum-version check, then the auth session, then
  /// feature switches").
  ///
  /// Returns the resumed session (also updating [currentSession] and
  /// emitting on [sessionChanges], same as any other sign-in method), or
  /// null if there is nothing to resume. Never throws for "nothing to
  /// resume" — only for a genuine failure to even check (e.g.
  /// [AuthNetworkError]).
  Future<AuthSession?> restoreSession();

  /// Requests a sign-in code be sent to [email].
  ///
  /// **Never reveals whether an account already exists for [email].** The
  /// returned [EmailCodeRequest] has exactly the same shape either way,
  /// and this method never throws a distinct error for "no such account"
  /// vs. "account exists" — both are indistinguishable successes from the
  /// caller's side (see `AppwriteAuthService`'s dartdoc for how the
  /// Appwrite adapter upholds this, and its one narrow, Appwrite-side
  /// residual edge case).
  ///
  /// Throws [AuthUnsupportedError] if
  /// `capabilities.supportsEmailCode` is false, [AuthRateLimitedError] if
  /// too many codes were requested for [email] recently, or
  /// [AuthNetworkError]/[AuthUnknownError] for other failures.
  Future<EmailCodeRequest> requestEmailCode(String email);

  /// Verifies [code] against a pending [request] (from
  /// [requestEmailCode]) and starts a session.
  ///
  /// Throws [AuthInvalidCodeError] if [code] is wrong,
  /// [AuthCodeExpiredError] if it was once valid but has expired, or
  /// [AuthRateLimitedError] after too many wrong attempts.
  Future<AuthSession> verifyEmailCode(EmailCodeRequest request, String code);

  /// Starts a passkey sign-in.
  ///
  /// Throws [AuthUnsupportedError] if `capabilities.supportsPasskeys` is
  /// false, or [AuthCancelledError] if the user dismissed the platform
  /// passkey prompt.
  Future<AuthSession> signInWithPasskey();

  /// Starts an OAuth sign-in with [provider].
  ///
  /// Throws [AuthUnsupportedError] if the matching
  /// `capabilities.supportsOAuth*` flag is false, or [AuthCancelledError]
  /// if the user closed the provider's sign-in page before completing it.
  Future<AuthSession> signInWithOAuth(OAuthProvider provider);

  /// Exchanges [code] for a session on the one allow-listed App Review
  /// demo account (see `apps/app/README.md`'s "App Review demo
  /// access" section for the full design). Never takes an email or
  /// password: the target account is fixed server-side (a Function
  /// variable, never the request — see
  /// `AppwriteAuthService.signInWithReviewCode`'s dartdoc), so this call
  /// can only ever authenticate as that one demo account, never an
  /// arbitrary one.
  ///
  /// Throws [AuthInvalidCodeError] if [code] is wrong, [AuthUnsupportedError]
  /// if this backend has no review demo account configured at all
  /// (`FakeAuthService` with no `reviewDemoCode`), or
  /// [AuthNetworkError]/[AuthUnknownError] for other failures.
  Future<AuthSession> signInWithReviewCode(String code);

  /// Ends the current session. A no-op (not an error) if already signed
  /// out.
  Future<void> signOut();

  /// Permanently deletes the current account and ends its session — see
  /// the plan's "Settings → Account" default screen. There is no
  /// confirmation step here; a screen confirms with the user before
  /// calling this.
  ///
  /// **Refused while the user owns a team**: deleting the
  /// account would leave the team without its owner, so the backend refuses
  /// server-side and nothing is deleted. A member or admin of a team (not
  /// its owner) deletes freely; the team's history outlives them.
  ///
  /// Throws [AuthOwnsTeamsError] (naming the teams) if the user owns any
  /// team, or [AuthUnauthenticatedError] if there is no current session.
  Future<void> deleteAccount();

  /// Lists external identities (OAuth providers, mainly) linked to the
  /// current account — backs the plan's "disconnect social login" row.
  ///
  /// Throws [AuthUnauthenticatedError] if there is no current session.
  Future<List<LinkedIdentity>> listIdentities();

  /// Unlinks the identity with [identityId] (from [listIdentities]) from
  /// the current account.
  ///
  /// Throws [AuthUnauthenticatedError] if there is no current session.
  Future<void> unlinkIdentity(String identityId);
}
