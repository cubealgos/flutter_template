import 'package:app/features/sign_in/sign_in_error.dart';
import 'package:app/features/sign_in/sign_in_step.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvc/mvc.dart';

part 'sign_in_model.freezed.dart';

/// `SignInView`'s view model: which step it's on, whether a request is in
/// flight, and the last error (if any).
@freezed
abstract class SignInModel with _$SignInModel implements ViewModel {
  /// Creates the model.
  const factory SignInModel({
    @Default(SignInStep.emailEntry) SignInStep step,
    @Default(false) bool submitting,
    SignInError? error,

    /// Seconds left before "Resend code" is tappable again — `0` means it
    /// is available now. Set by `SignInController` after a code is sent
    /// (initial request or resend), spec.md §2.3's ~30-60s resend cooldown.
    @Default(0) int secondsRemaining,
  }) = _SignInModel;
}
