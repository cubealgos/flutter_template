import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvc/mvc.dart';

part 'legal_hub_model.freezed.dart';

/// `LegalHubView`'s view model: whether to show the Barrierefreiheit row
/// (behind `AppConfig.accessibilityStatement`).
@freezed
abstract class LegalHubModel with _$LegalHubModel implements ViewModel {
  /// Creates the model.
  const factory LegalHubModel({required bool showAccessibilityStatement}) =
      _LegalHubModel;
}
