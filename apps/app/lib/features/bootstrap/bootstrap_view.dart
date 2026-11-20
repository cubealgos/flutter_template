import 'package:app/app/config.dart';
import 'package:app/app/di.dart';
import 'package:app/features/bootstrap/bootstrap_controller.dart';
import 'package:app/features/bootstrap/bootstrap_model.dart';
import 'package:app/features/bootstrap/layouts/bootstrap_mobile_layout.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// Bootstrap/splash: resolves the minimum-version check, then the auth
/// session, then feature switches, navigating away as soon as it knows
/// where to go — the only state this screen ever actually renders is a
/// blocked version check (see `BootstrapController`'s dartdoc).
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `BootstrapMobileLayout` (mobile only — every wider
/// viewport falls back to it).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class BootstrapView extends ViewWidget<BootstrapModel, BootstrapController> {
  /// Creates the view.
  BootstrapView({super.key});

  @override
  BootstrapController createController() => BootstrapController(
    getIt<NavigationService>(),
    getIt<LauncherService>(),
    getIt<VersionPolicy>(),
    getIt<AuthService>(),
    getIt<AppConfig>(),
    getIt<UserPreferences>(),
  );

  @override
  Widget build(
    BuildContext context,
    BootstrapController controller,
    BootstrapModel model,
  ) {
    return ResponsiveLayout(
      mobile: (_) => BootstrapMobileLayout(
        model: model,
        onOpenUpdateLink: controller.openUpdateLink,
      ),
    );
  }
}
