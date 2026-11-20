import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvc/mvc.dart';

part 'settings_hub_model.freezed.dart';

/// `SettingsHubView`'s view model: whether to show the Subscription row
/// (behind `AppConfig.paywall`).
@freezed
abstract class SettingsHubModel with _$SettingsHubModel implements ViewModel {
  /// Creates the model.
  const factory SettingsHubModel({required bool showPaywall}) =
      _SettingsHubModel;
}
