/// The OAuth providers `AuthService.signInWithOAuth` supports — see the
/// plan's "Default screens" section: "Apple and Google buttons".
///
/// Deliberately a small, closed set rather than passing through Appwrite's
/// own much larger `enums.OAuthProvider` (dozens of providers this
/// template's default screens never use) — an app that needs another
/// provider extends this enum directly, since it owns this package outright
/// after cloning (see the root `CLAUDE.md`: "each app clones this repo and
/// then owns its copy outright").
enum OAuthProvider {
  /// Sign in with Apple.
  apple,

  /// Sign in with Google.
  google,
}
