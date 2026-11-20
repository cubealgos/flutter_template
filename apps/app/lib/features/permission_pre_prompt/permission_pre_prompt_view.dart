import 'package:app/app/di.dart';
import 'package:app/features/permission_pre_prompt/layouts/permission_pre_prompt_mobile_layout.dart';
import 'package:app/features/permission_pre_prompt/permission_kind.dart';
import 'package:app/features/permission_pre_prompt/permission_pre_prompt_controller.dart';
import 'package:app/features/permission_pre_prompt/permission_pre_prompt_model.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// A reusable pre-permission prompt: explains the value of a system
/// permission (push, App Tracking Transparency, location) *before* the
/// real platform prompt appears, with "Continue"/"Not now" — never
/// mimicking the OS dialog's look (it's built entirely from this
/// template's own `AppDialog` chrome and tokens, not a system-styled
/// alert).
///
/// Show via `DialogService.show`, e.g.:
/// ```dart
/// await getIt<DialogService>().show(
///   (context) => PermissionPrePromptView(
///     kind: PermissionKind.push,
///     onContinue: () {
///       // Request the real platform permission here (this template adds
///       // no platform-permission package dependency).
///     },
///   ),
/// );
/// ```
///
/// The only `ViewWidget` of the feature: it owns the controller and builds a
/// `ResponsiveLayout` of `PermissionPrePromptMobileLayout` (mobile only — every
/// wider viewport falls back to it) (a dialog keeps one shape on every
/// viewport).
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class PermissionPrePromptView
    extends
        ViewWidget<PermissionPrePromptModel, PermissionPrePromptController> {
  /// Creates the view for [kind], calling [onContinue] if the user
  /// continues.
  PermissionPrePromptView({
    required this.kind,
    required this.onContinue,
    super.key,
  });

  /// Which permission this prompt explains.
  final PermissionKind kind;

  /// Called when the user chooses to continue.
  final VoidCallback onContinue;

  @override
  PermissionPrePromptController createController() =>
      PermissionPrePromptController(
        getIt<DialogService>(),
        kind: kind,
        onContinue: onContinue,
      );

  @override
  Widget build(
    BuildContext context,
    PermissionPrePromptController controller,
    PermissionPrePromptModel model,
  ) {
    return ResponsiveLayout(
      mobile: (_) => PermissionPrePromptMobileLayout(
        model: model,
        onNotNow: controller.notNowPressed,
        onContinue: controller.continuePressed,
      ),
    );
  }
}
