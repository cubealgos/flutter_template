import 'package:app/features/permission_pre_prompt/permission_kind.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvc/mvc.dart';

part 'permission_pre_prompt_model.freezed.dart';

/// `PermissionPrePromptView`'s view model: which permission it's about.
@freezed
abstract class PermissionPrePromptModel
    with _$PermissionPrePromptModel
    implements ViewModel {
  /// Creates the model for [kind].
  const factory PermissionPrePromptModel({required PermissionKind kind}) =
      _PermissionPrePromptModel;
}
