import 'package:app/app/di.dart';
import 'package:app/features/legal/licences/layouts/licences_mobile_layout.dart';
import 'package:app/features/legal/licences/licences_controller.dart';
import 'package:app/features/legal/licences/licences_model.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// The OSS licences page, built from `LicenseRegistry.licenses` directly —
/// this template forbids Material widgets, so `showLicensePage` (which is
/// one) is never used.
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `LicencesMobileLayout` (mobile only — every wider
/// viewport falls back to it).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class LicencesView extends ViewWidget<LicencesModel, LicencesController> {
  /// Creates the view.
  LicencesView({super.key});

  @override
  LicencesController createController() =>
      LicencesController(getIt<NavigationService>(), getIt<ClipboardService>());

  @override
  Widget build(
    BuildContext context,
    LicencesController controller,
    LicencesModel model,
  ) {
    return ResponsiveLayout(
      mobile: (_) => LicencesMobileLayout(
        model: model,
        onBack: controller.goBack,
        onCopyLicenceText: controller.copyLicenceText,
      ),
    );
  }
}
