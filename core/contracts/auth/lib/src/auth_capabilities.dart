import 'package:auth/src/auth_service.dart';
import 'package:auth/src/oauth_provider.dart';

/// What a given [AuthService] implementation actually supports.
///
/// A screen reads this (not the concrete service type) to decide which
/// sign-in buttons to show — see the plan's "Default screens" section:
/// "a passkey button *(switch; depends on what Appwrite supports)*, and
/// Apple and Google buttons *(switch; enabling Google forces Apple under
/// guideline 4.8)*". `FakeAuthService` defaults every flag to true so
/// screen tests can exercise every path; `AppwriteAuthService` reports
/// what the self-hosted Appwrite version it talks to actually offers —
/// see that class's dartdoc for the passkey finding.
class AuthCapabilities {
  /// Declares which flows this backend supports.
  const AuthCapabilities({
    this.supportsEmailCode = true,
    this.supportsPasskeys = false,
    this.supportsOAuthApple = false,
    this.supportsOAuthGoogle = false,
  });

  /// Whether [AuthService.requestEmailCode]/[AuthService.verifyEmailCode]
  /// (email OTP) are supported.
  final bool supportsEmailCode;

  /// Whether [AuthService.signInWithPasskey] is supported. Defaults to
  /// false: as of Appwrite 26.2.0's client SDK (the version behind this
  /// template's `appwrite_adapters` adapter), the `Account` service has no
  /// passkey/WebAuthn methods at all — see `AppwriteAuthService`'s dartdoc.
  final bool supportsPasskeys;

  /// Whether [AuthService.signInWithOAuth] with
  /// [OAuthProvider.apple] is supported.
  final bool supportsOAuthApple;

  /// Whether [AuthService.signInWithOAuth] with
  /// [OAuthProvider.google] is supported. Per Apple guideline 4.8, a
  /// screen that turns this on must also turn [supportsOAuthApple] on.
  final bool supportsOAuthGoogle;
}
