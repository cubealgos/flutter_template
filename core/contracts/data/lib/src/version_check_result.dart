/// The outcome of a `VersionPolicy` check.
class VersionCheckResult {
  /// Creates a result. A non-[blocked] result never carries [updateUrl]/
  /// [message] — nothing reads them in that case.
  const VersionCheckResult({
    required this.blocked,
    this.updateUrl,
    this.message,
  });

  /// A convenience constant for "this version is fine, keep going".
  static const VersionCheckResult allowed = VersionCheckResult(blocked: false);

  /// Whether the caller's version is below the minimum supported version —
  /// the bootstrap/splash screen (see the plan's "Default screens"
  /// section) shows a blocking "please update" screen instead of
  /// continuing when this is true.
  final bool blocked;

  /// Where to send the user to update, e.g. an App/Play Store or web
  /// download link. Opened via `LauncherService`, never `url_launcher`
  /// directly (this is read by a controller, not a view).
  final Uri? updateUrl;

  /// A human-readable reason, for logs — not localized, not shown as UI
  /// copy (the blocked screen uses its own translated string).
  final String? message;
}
