import 'package:app/features/settings/privacy/consent_status.dart';
import 'package:app/features/settings/privacy/export_error.dart';
import 'package:app/features/settings/privacy/export_phase.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvc/mvc.dart';

part 'privacy_settings_model.freezed.dart';

/// `PrivacySettingsView`'s view model: the current consent status, and
/// the data-export flow's state.
@freezed
abstract class PrivacySettingsModel
    with _$PrivacySettingsModel
    implements ViewModel {
  /// Creates the model.
  const factory PrivacySettingsModel({
    @Default(ConsentStatus.notSet) ConsentStatus consentStatus,
    @Default(ExportPhase.idle) ExportPhase exportPhase,

    /// The export flow's typed failure, if any — see [ExportError].
    ExportError? exportError,

    /// The exported data as JSON, once [exportPhase] is
    /// [ExportPhase.result].
    String? exportedJson,
  }) = _PrivacySettingsModel;
}
