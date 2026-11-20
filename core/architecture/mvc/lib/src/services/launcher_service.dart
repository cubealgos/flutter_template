import 'package:url_launcher/url_launcher.dart';

/// Opening external URLs (a browser tab, a mail client, a phone dialer),
/// injected into a `ViewController` instead of a view calling `url_launcher`
/// itself.
///
/// A controller depends on this interface, not on [UrlLauncherService]
/// directly, so a controller unit test can inject a fake/mock instead of
/// touching the platform. `core/architecture/mvc_lints`' `avoid_view_restricted_imports`
/// rule enforces the other half of the boundary: a view may not import
/// `url_launcher` at all — only a controller, via this service, may launch a
/// URL.
abstract class LauncherService {
  /// Opens [url] in the appropriate external handler for its scheme
  /// (browser for `https`, mail client for `mailto`, dialer for `tel`, …).
  ///
  /// [external] forces the platform's separate/external application (e.g.
  /// the default browser) rather than an in-app presentation, where the
  /// platform supports the distinction; ignored otherwise. Returns whether
  /// the platform reported the URL as launched.
  Future<bool> openUrl(Uri url, {bool external = false});

  /// Returns whether the platform reports having a handler capable of
  /// opening [url], without actually opening it.
  Future<bool> canOpen(Uri url);
}

/// The default [LauncherService], wrapping `package:url_launcher`'s
/// top-level `launchUrl`/`canLaunchUrl` functions.
///
/// This is the only file in `package:mvc` (besides its own test) that may
/// import `package:url_launcher` — see [LauncherService].
class UrlLauncherService implements LauncherService {
  /// Creates the service. Stateless — `url_launcher`'s platform channel is
  /// process-global, so there is nothing to inject here; the seam this
  /// class exists for is the [LauncherService] interface it implements, not
  /// constructor state.
  const UrlLauncherService();

  @override
  Future<bool> openUrl(Uri url, {bool external = false}) {
    return launchUrl(
      url,
      mode: external
          ? LaunchMode.externalApplication
          : LaunchMode.platformDefault,
    );
  }

  @override
  Future<bool> canOpen(Uri url) => canLaunchUrl(url);
}
