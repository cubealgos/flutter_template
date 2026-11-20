import 'package:app/app/config.dart';
import 'package:app/app/di.dart';
import 'package:app/features/sign_in/layouts/sign_in_desktop_layout.dart';
import 'package:app/features/sign_in/layouts/sign_in_mobile_layout.dart';
import 'package:app/features/sign_in/sign_in_controller.dart';
import 'package:app/features/sign_in/sign_in_model.dart';
import 'package:app/features/sign_in/widgets/sign_in_form.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// Email-first sign-in: email → code (OTP), a passkey button and
/// Apple/Google buttons behind their switches, an App Review demo
/// shortcut, and legal links — all pre-login. **Never reveals whether
/// an account exists**: the UI response is identical whether the entered
/// email is new or already registered (see `SignInController`'s dartdoc).
///
/// The only `ViewWidget` of the feature: it owns the controller and builds
/// one `SignInForm`, laid out by `ResponsiveLayout` as `SignInMobileLayout`
/// (top-anchored) or `SignInDesktopLayout` (vertically centered; no tablet
/// layout). The two layouts differ only in that wrapper, so they take the
/// prebuilt form rather than repeating its twenty callbacks.
///
/// Stays dumb per the MVC view rule: no navigation, no service imports
/// beyond the injected controller — enforced by `core/architecture/mvc_lints`.
class SignInView extends ViewWidget<SignInModel, SignInController> {
  /// Creates the view.
  SignInView({super.key});

  @override
  SignInController createController() => SignInController(
    getIt<NavigationService>(),
    getIt<AuthService>(),
    getIt<AppConfig>(),
    getIt<UserPreferences>(),
  );

  @override
  Widget build(
    BuildContext context,
    SignInController controller,
    SignInModel model,
  ) {
    final form = SignInForm(
      model: model,
      emailController: controller.emailController,
      codeController: controller.codeController,
      reviewCodeController: controller.reviewCodeController,
      showPasskeyButton: controller.showPasskeyButton,
      showAppleButton: controller.showAppleButton,
      showGoogleButton: controller.showGoogleButton,
      showReviewerButton: controller.showReviewerButton,
      onRequestCode: controller.requestCode,
      onVerifyCode: controller.verifyCode,
      onResendCode: controller.resendCode,
      onChangeEmail: controller.changeEmail,
      onSubmitReviewCode: controller.submitReviewCode,
      onSignInWithPasskey: controller.signInWithPasskey,
      onSignInWithApple: controller.signInWithApple,
      onSignInWithGoogle: controller.signInWithGoogle,
      onContinueAsReviewer: controller.continueAsReviewer,
      onOpenLegal: controller.openLegal,
      onOpenAgb: controller.openAgb,
      onOpenDatenschutz: controller.openDatenschutz,
    );

    return ResponsiveLayout(
      mobile: (_) => SignInMobileLayout(form: form),
      desktop: (_) => SignInDesktopLayout(form: form),
    );
  }
}
