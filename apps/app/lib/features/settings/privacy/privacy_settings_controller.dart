import 'dart:async';
import 'dart:convert';

import 'package:app/app/preference_keys.dart';
import 'package:app/features/settings/privacy/consent_status.dart';
import 'package:app/features/settings/privacy/export_error.dart';
import 'package:app/features/settings/privacy/export_phase.dart';
import 'package:app/features/settings/privacy/privacy_settings_model.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// Drives `PrivacySettingsView`: change consent (withdrawable at any
/// time — the same [consentAcceptedPreferenceKey] `ConsentController`
/// writes) and export the user's own data with step-up re-verification.
///
/// Step-up re-verification reuses [AuthService.requestEmailCode]/
/// [AuthService.verifyEmailCode] rather than a dedicated
/// re-authentication method — there is no separate one in this
/// interface, and issuing/checking a fresh email code before a sensitive
/// action is exactly what those two already do.
class PrivacySettingsController extends ViewController<PrivacySettingsModel> {
  /// Creates the controller with every service it needs injected.
  PrivacySettingsController(
    this._navigation,
    this._preferences,
    this._auth,
    this._documents,
    this._clipboard,
  ) : super(const PrivacySettingsModel());

  final NavigationService _navigation;
  final UserPreferences _preferences;
  final AuthService _auth;
  final DocumentRepository _documents;
  final ClipboardService _clipboard;
  EmailCodeRequest? _pendingStepUpRequest;

  /// The step-up code field's controller — owned here, not by the view,
  /// so it survives the view's rebuilds (a fresh `TextEditingController`
  /// created inside `build` would drop whatever the user had typed on the
  /// very next model change).
  final TextEditingController stepUpCodeController = TextEditingController();

  @override
  void init() {
    unawaited(_loadConsent());
  }

  @override
  void dispose() {
    stepUpCodeController.dispose();
    super.dispose();
  }

  /// Records a new consent choice.
  Future<void> setConsent({required bool accepted}) async {
    await _preferences.update(<String, dynamic>{
      consentAcceptedPreferenceKey: accepted,
    });
    value = value.copyWith(
      consentStatus: accepted ? ConsentStatus.accepted : ConsentStatus.rejected,
    );
  }

  /// Starts the export flow: requests a fresh step-up code for the
  /// current session's email.
  Future<void> startExport() async {
    final email = _auth.currentSession?.email;
    if (email == null) {
      value = value.copyWith(exportError: ExportError.noEmail);

      return;
    }

    try {
      _pendingStepUpRequest = await _auth.requestEmailCode(email);
      value = value.copyWith(
        exportPhase: ExportPhase.stepUp,
        exportError: null,
      );
    } on AuthError {
      value = value.copyWith(exportError: ExportError.requestFailed);
    }
  }

  /// Verifies the step-up [code] and, if correct, exports every document
  /// in the user's `profiles` collection as JSON.
  Future<void> verifyStepUpAndExport(String code) async {
    final request = _pendingStepUpRequest;
    if (request == null) return;

    try {
      await _auth.verifyEmailCode(request, code);
    } on AuthError {
      value = value.copyWith(exportError: ExportError.invalidCode);

      return;
    }

    value = value.copyWith(
      exportPhase: ExportPhase.exporting,
      exportError: null,
    );
    final documents = await _documents.query();
    final json = jsonEncode(
      documents
          .map(
            (document) => <String, dynamic>{
              'id': document.id,
              ...document.data,
            },
          )
          .toList(),
    );
    value = value.copyWith(exportPhase: ExportPhase.result, exportedJson: json);
  }

  /// Copies the exported JSON to the system clipboard, via the injected
  /// [ClipboardService] — this template has no Material `SelectableText`
  /// to reach for instead. A no-op before [ExportPhase.result].
  Future<void> copyExportedJson() async {
    final json = value.exportedJson;
    if (json == null) return;
    await _clipboard.copyText(json);
  }

  /// Pops back to the previous screen, if there is one to pop back to.
  void goBack() {
    if (_navigation.canPop()) _navigation.pop();
  }

  Future<void> _loadConsent() async {
    final prefs = await _preferences.getAll();
    final consentValue = prefs[consentAcceptedPreferenceKey];
    value = value.copyWith(
      consentStatus: switch (consentValue) {
        true => ConsentStatus.accepted,
        false => ConsentStatus.rejected,
        _ => ConsentStatus.notSet,
      },
    );
  }
}
