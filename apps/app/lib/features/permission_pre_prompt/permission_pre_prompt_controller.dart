import 'package:app/features/permission_pre_prompt/permission_kind.dart';
import 'package:app/features/permission_pre_prompt/permission_pre_prompt_model.dart';
import 'package:flutter/foundation.dart';
import 'package:mvc/mvc.dart';

/// Drives `PermissionPrePromptView`: "Continue" runs the caller-supplied
/// [onContinue] (where a real app would request the actual platform
/// permission — this template adds no platform-permission dependency, so
/// that call is left to the caller) and then closes the overlay; "Not now"
/// just closes it. Shown in context via `DialogService.show`, never as a
/// blocking gate the user can't decline.
class PermissionPrePromptController
    extends ViewController<PermissionPrePromptModel> {
  /// Creates the controller for [kind], with [_dialogService] injected and
  /// [onContinue] supplied by whichever screen shows this prompt.
  PermissionPrePromptController(
    this._dialogService, {
    required PermissionKind kind,
    required this.onContinue,
  }) : super(PermissionPrePromptModel(kind: kind));

  final DialogService _dialogService;

  /// Called when the user chooses to continue — the caller wires this to
  /// the real platform permission request.
  final VoidCallback onContinue;

  /// Runs [onContinue] and closes the overlay with `true`.
  void continuePressed() {
    onContinue();
    _dialogService.close(true);
  }

  /// Closes the overlay with `false`, without running [onContinue].
  void notNowPressed() => _dialogService.close(false);
}
