import 'dart:async';

import 'package:app/app/config.dart';
import 'package:app/app/post_auth_location.dart';
import 'package:app/app/router.dart';
import 'package:app/features/bootstrap/bootstrap_model.dart';
import 'package:app/features/bootstrap/bootstrap_status.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:mvc/mvc.dart';

/// Drives `BootstrapView`: resolves the minimum-version check, then the
/// auth session, then feature switches (see the plan's "Bootstrap/splash"
/// default screen) — in that order, each step gating the next.
class BootstrapController extends ViewController<BootstrapModel> {
  /// Creates the controller with every service it needs injected.
  BootstrapController(
    this._navigation,
    this._launcher,
    this._versionPolicy,
    this._auth,
    this._config,
    this._preferences,
  ) : super(const BootstrapModel());

  final NavigationService _navigation;
  final LauncherService _launcher;
  final VersionPolicy _versionPolicy;
  final AuthService _auth;
  final AppConfig _config;
  final UserPreferences _preferences;

  @override
  void init() {
    unawaited(_run());
  }

  /// Opens the store/update link from a blocked version check.
  Future<void> openUpdateLink() async {
    final url = value.updateUrl;
    if (url != null) await _launcher.openUrl(url, external: true);
  }

  Future<void> _run() async {
    final versionResult = await _versionPolicy.check(_config.appVersion);
    if (versionResult.blocked) {
      value = value.copyWith(
        status: BootstrapStatus.blocked,
        updateUrl: versionResult.updateUrl,
        updateMessage: versionResult.message,
      );

      return;
    }

    final session = await _auth.restoreSession();
    if (session == null) {
      _navigation.go(const SignInRoute().location);

      return;
    }

    final location = await resolvePostAuthLocation(
      config: _config,
      preferences: _preferences,
    );
    _navigation.go(location);
  }
}
