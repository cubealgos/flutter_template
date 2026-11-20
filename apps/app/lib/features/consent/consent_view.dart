import 'package:app/app/di.dart';
import 'package:app/features/consent/consent_controller.dart';
import 'package:app/features/consent/consent_model.dart';
import 'package:app/features/consent/layouts/consent_mobile_layout.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// The consent sheet: Accept and Reject as two equal-weight buttons on one
/// layer — neither pre-selected, neither visually or semantically
/// dominant, satisfying §25 TDDDG / the Planet49 and LG München I rulings
/// (see the plan's "Default screens" section). Includes a link to Settings
/// → Privacy, and no checkbox is ever pre-ticked.
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `ConsentMobileLayout` (mobile only — every wider
/// viewport falls back to it).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class ConsentView extends ViewWidget<ConsentModel, ConsentController> {
  /// Creates the view.
  ConsentView({super.key});

  @override
  ConsentController createController() =>
      ConsentController(getIt<NavigationService>(), getIt<UserPreferences>());

  @override
  Widget build(
    BuildContext context,
    ConsentController controller,
    ConsentModel model,
  ) {
    return ResponsiveLayout(
      mobile: (_) => ConsentMobileLayout(
        onReject: controller.reject,
        onAccept: controller.accept,
        onOpenSettings: controller.openSettings,
      ),
    );
  }
}
