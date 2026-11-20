import 'package:app/features/bootstrap/bootstrap_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvc/mvc.dart';

part 'bootstrap_model.freezed.dart';

/// `BootstrapView`'s view model.
@freezed
abstract class BootstrapModel with _$BootstrapModel implements ViewModel {
  /// Creates the model.
  const factory BootstrapModel({
    @Default(BootstrapStatus.checking) BootstrapStatus status,
    Uri? updateUrl,
    String? updateMessage,
  }) = _BootstrapModel;
}
