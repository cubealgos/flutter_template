/// Where `BootstrapView` is in its three-step resolution: the min-version
/// check, then the auth session, then feature switches (see the plan's
/// "Bootstrap/splash" default screen). [checking] covers both the version
/// check and, once that passes, the session restore/routing — this screen
/// never renders anything for those beyond a brief loading state, since
/// they always end in a navigation away. [blocked] is the one state that
/// actually stays on screen.
enum BootstrapStatus {
  /// Still checking — nothing to show but a brief loading state.
  checking,

  /// The running version is below the backend's minimum supported
  /// version; `BootstrapModel.updateUrl`/`BootstrapModel.updateMessage`
  /// describe what to show.
  blocked,
}
