import 'package:app/features/sign_in/sign_in_error.dart';
import 'package:app/features/sign_in/sign_in_model.dart';
import 'package:app/features/sign_in/sign_in_step.dart';
import 'package:app/features/sign_in/widgets/alternative_button.dart';
import 'package:app/features/sign_in/widgets/or_divider.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:app/shared/widgets/legal_links_row.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The sign-in form every layout wraps: the title, the current step
/// (email → code, or the App Review demo code), the alternative-method
/// buttons and the legal links. **Never reveals whether an account exists**
/// (see `SignInController`'s dartdoc).
class SignInForm extends StatelessWidget {
  /// Creates the form.
  const SignInForm({
    required this.model,
    required this.emailController,
    required this.codeController,
    required this.reviewCodeController,
    required this.showPasskeyButton,
    required this.showAppleButton,
    required this.showGoogleButton,
    required this.showReviewerButton,
    required this.onRequestCode,
    required this.onVerifyCode,
    required this.onResendCode,
    required this.onChangeEmail,
    required this.onSubmitReviewCode,
    required this.onSignInWithPasskey,
    required this.onSignInWithApple,
    required this.onSignInWithGoogle,
    required this.onContinueAsReviewer,
    required this.onOpenLegal,
    required this.onOpenAgb,
    required this.onOpenDatenschutz,
    super.key,
  });

  /// The sign-in state being rendered.
  final SignInModel model;

  /// The email field's text controller.
  final TextEditingController emailController;

  /// The one-time-code field's text controller.
  final TextEditingController codeController;

  /// The App Review demo code field's text controller.
  final TextEditingController reviewCodeController;

  /// Whether the passkey button is offered.
  final bool showPasskeyButton;

  /// Whether the "Sign in with Apple" button is offered.
  final bool showAppleButton;

  /// Whether the "Sign in with Google" button is offered.
  final bool showGoogleButton;

  /// Whether the App Review demo shortcut is offered.
  final bool showReviewerButton;

  /// Called when the email step is submitted.
  final VoidCallback onRequestCode;

  /// Called when the code step is submitted.
  final VoidCallback onVerifyCode;

  /// Called when "resend code" is pressed.
  final VoidCallback onResendCode;

  /// Called when "change email" is pressed.
  final VoidCallback onChangeEmail;

  /// Called when the App Review demo code is submitted.
  final VoidCallback onSubmitReviewCode;

  /// Called when the passkey button is pressed.
  final VoidCallback onSignInWithPasskey;

  /// Called when the Apple button is pressed.
  final VoidCallback onSignInWithApple;

  /// Called when the Google button is pressed.
  final VoidCallback onSignInWithGoogle;

  /// Called when the App Review demo shortcut is pressed.
  final VoidCallback onContinueAsReviewer;

  /// Called when the Legal hub link is pressed.
  final VoidCallback onOpenLegal;

  /// Called when the AGB link is pressed.
  final VoidCallback onOpenAgb;

  /// Called when the Datenschutz link is pressed.
  final VoidCallback onOpenDatenschutz;

  List<Widget> _emailStep() {
    return <Widget>[
      AppTextField(label: t.signIn.emailLabel, controller: emailController),
      const AppGap.v2(),
      AppFullWidthButton(
        child: AppButton(
          semanticLabel: t.signIn.requestCodeButton,
          loading: model.submitting,
          onPressed: onRequestCode,
          child: Text(t.signIn.requestCodeButton),
        ),
      ),
    ];
  }

  List<Widget> _codeStep() {
    final error = model.error;

    return <Widget>[
      StyledText(
        t.signIn.codeHint(email: emailController.text),
        style: bodyStyle(),
      ),
      const AppGap.v2(),
      AppCodeField(
        label: t.signIn.codeLabel,
        controller: codeController,
        errorText: error != null ? _errorText(error) : null,
      ),
      const AppGap.v2(),
      AppFullWidthButton(
        child: AppButton(
          semanticLabel: t.signIn.verifyButton,
          loading: model.submitting,
          onPressed: onVerifyCode,
          child: Text(t.signIn.verifyButton),
        ),
      ),
      const AppGap.v4(),
      AppResendButton(
        label: t.signIn.resendCodeButton,
        secondsRemaining: model.secondsRemaining,
        onPressed: onResendCode,
      ),
      const AppGap.v2(),
      AppTextLinkButton(
        label: t.signIn.changeEmailButton,
        onPressed: onChangeEmail,
      ),
    ];
  }

  /// The App Review demo code step — split out into its own method, like
  /// [_emailStep] and [_codeStep], so `build` itself stays within this
  /// workspace's function-length threshold.
  List<Widget> _reviewCodeStep() {
    return <Widget>[
      StyledText(t.signIn.reviewCodeHint, style: bodyStyle()),
      const AppGap.v2(),
      AppTextField(
        label: t.signIn.reviewCodeLabel,
        controller: reviewCodeController,
      ),
      const AppGap.v2(),
      AppFullWidthButton(
        child: AppButton(
          semanticLabel: t.signIn.reviewerSubmitButton,
          loading: model.submitting,
          onPressed: onSubmitReviewCode,
          child: Text(t.signIn.reviewerSubmitButton),
        ),
      ),
      const AppGap.v2(),
      AppTextLinkButton(
        label: t.signIn.changeEmailButton,
        onPressed: onChangeEmail,
      ),
    ];
  }

  List<Widget> _stepSection() {
    return switch (model.step) {
      SignInStep.emailEntry => _emailStep(),
      SignInStep.codeEntry => _codeStep(),
      SignInStep.reviewCode => _reviewCodeStep(),
    };
  }

  String _errorText(SignInError error) => switch (error) {
    SignInError.generic => t.signIn.errorGeneric,
    SignInError.invalidCode => t.signIn.errorInvalidCode,
    SignInError.rateLimited => t.signIn.errorRateLimited,
  };

  List<Widget> _alternativeSignInMethods() {
    final buttons = <Widget>[
      if (showPasskeyButton)
        AlternativeButton(
          semanticLabel: t.signIn.passkeyButton,
          onPressed: onSignInWithPasskey,
          label: t.signIn.passkeyButton,
        ),
      if (showAppleButton)
        AlternativeButton(
          semanticLabel: t.signIn.appleButton,
          onPressed: onSignInWithApple,
          label: t.signIn.appleButton,
        ),
      if (showGoogleButton)
        AlternativeButton(
          semanticLabel: t.signIn.googleButton,
          onPressed: onSignInWithGoogle,
          label: t.signIn.googleButton,
        ),
      if (showReviewerButton)
        AlternativeButton(
          semanticLabel: t.signIn.reviewerButton,
          onPressed: onContinueAsReviewer,
          label: t.signIn.reviewerButton,
        ),
    ];
    if (buttons.isEmpty) return <Widget>[];

    return <Widget>[const OrDivider(), ...buttons];
  }

  @override
  Widget build(BuildContext context) {
    final showAlternatives = model.step == SignInStep.emailEntry;

    return Box(
      style: BoxStyler().paddingAll(space6()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StyledText(t.signIn.title, style: h1Style()),
          const AppGap.v6(),
          ..._stepSection(),
          if (showAlternatives) ..._alternativeSignInMethods(),
          if (showAlternatives) ...<Widget>[
            const AppGap.v6(),
            LegalLinksRow(
              onOpenLegal: onOpenLegal,
              onOpenAgb: onOpenAgb,
              onOpenDatenschutz: onOpenDatenschutz,
            ),
          ],
        ],
      ),
    );
  }
}
