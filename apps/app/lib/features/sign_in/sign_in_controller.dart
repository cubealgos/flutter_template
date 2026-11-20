import 'dart:async';

import 'package:app/app/config.dart';
import 'package:app/app/post_auth_location.dart';
import 'package:app/app/router.dart';
import 'package:app/features/sign_in/sign_in_error.dart';
import 'package:app/features/sign_in/sign_in_model.dart';
import 'package:app/features/sign_in/sign_in_step.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';
import 'package:mvc/mvc.dart';

/// How long "Resend code" stays disabled after a code is sent (initial
/// request or resend) — spec.md §2.3's evidence table: "~30-60s with a
/// visible countdown, never fully hidden".
const int _resendCooldownSeconds = 30;

/// Drives `SignInView`: email-first sign-in (OTP), passkey/Apple/Google
/// behind switches, and a documented App Review demo path — see the
/// plan's "Sign-in, email first" default screen and
/// `apps/app/README.md`'s "App Review demo access" section.
///
/// **Never reveals whether an account exists** — [requestCode] shows the
/// same UI response (moves to the code-entry step) whether [AuthService]
/// found an existing account or created one, matching
/// `AuthService.requestEmailCode`'s own documented contract.
class SignInController extends ViewController<SignInModel> {
  /// Creates the controller with every service it needs injected.
  SignInController(
    this._navigation,
    this._auth,
    this._config,
    this._preferences,
  ) : super(const SignInModel());

  final NavigationService _navigation;
  final AuthService _auth;
  final AppConfig _config;
  final UserPreferences _preferences;
  EmailCodeRequest? _pendingRequest;
  Timer? _cooldownTimer;

  /// The email field's controller — owned here so it survives the view's
  /// rebuilds (see `PrivacySettingsController.stepUpCodeController`'s
  /// dartdoc for why).
  final TextEditingController emailController = TextEditingController();

  /// The code field's controller — see [emailController]'s dartdoc.
  final TextEditingController codeController = TextEditingController();

  /// The App Review demo shared code field's controller — see
  /// [emailController]'s dartdoc.
  final TextEditingController reviewCodeController = TextEditingController();

  /// What this backend actually supports — the view reads this (via
  /// [showPasskeyButton] etc. below) to decide which buttons to show,
  /// never hard-coding which flows exist.
  AuthCapabilities get capabilities => _auth.capabilities;

  /// Whether to show the passkey button — both the feature switch and the
  /// backend capability must allow it (the passkey switch is
  /// disabled whenever the backend reports `supportsPasskeys == false`).
  bool get showPasskeyButton =>
      _config.passkeys && capabilities.supportsPasskeys;

  /// Whether to show "Sign in with Apple".
  bool get showAppleButton =>
      _config.socialLoginApple && capabilities.supportsOAuthApple;

  /// Whether to show "Sign in with Google" (the AppConfig assert already
  /// forces [AppConfig.socialLoginApple] on whenever this is, per App
  /// Store guideline 4.8).
  bool get showGoogleButton =>
      _config.socialLoginGoogle && capabilities.supportsOAuthGoogle;

  /// Whether to show the App Review demo shortcut.
  bool get showReviewerButton => _config.reviewDemoEnabled;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    emailController.dispose();
    codeController.dispose();
    reviewCodeController.dispose();
    super.dispose();
  }

  /// Requests a sign-in code for the entered email, moves to the
  /// code-entry step, and starts the "Resend code" cooldown.
  Future<void> requestCode() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    value = value.copyWith(submitting: true, error: null);
    try {
      _pendingRequest = await _auth.requestEmailCode(email);
      value = value.copyWith(step: SignInStep.codeEntry, submitting: false);
      _startCooldown();
    } on AuthRateLimitedError {
      value = value.copyWith(submitting: false, error: SignInError.rateLimited);
    } on AuthError {
      value = value.copyWith(submitting: false, error: SignInError.generic);
    }
  }

  /// Requests a fresh sign-in code for the same email, without leaving the
  /// code-entry step, and restarts the cooldown. A no-op while the
  /// cooldown from a previous request/resend hasn't elapsed yet — the view
  /// only offers this as a tappable link once [SignInModel.secondsRemaining]
  /// reaches zero, but this guards the same invariant here too.
  Future<void> resendCode() async {
    if (value.secondsRemaining > 0) return;
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    try {
      _pendingRequest = await _auth.requestEmailCode(email);
      value = value.copyWith(error: null);
      _startCooldown();
    } on AuthRateLimitedError {
      value = value.copyWith(error: SignInError.rateLimited);
    } on AuthError {
      value = value.copyWith(error: SignInError.generic);
    }
  }

  /// Verifies the entered code and, if correct, completes sign-in.
  Future<void> verifyCode() async {
    final request = _pendingRequest;
    if (request == null) return;

    value = value.copyWith(submitting: true, error: null);
    try {
      await _auth.verifyEmailCode(request, codeController.text.trim());
      await _completeSignIn();
    } on AuthInvalidCodeError {
      value = value.copyWith(submitting: false, error: SignInError.invalidCode);
    } on AuthCodeExpiredError {
      value = value.copyWith(submitting: false, error: SignInError.invalidCode);
    } on AuthRateLimitedError {
      value = value.copyWith(submitting: false, error: SignInError.rateLimited);
    } on AuthError {
      value = value.copyWith(submitting: false, error: SignInError.generic);
    }
  }

  /// Returns to the email-entry step, discarding any pending code request
  /// or in-progress reviewer sign-in.
  void changeEmail() {
    _cooldownTimer?.cancel();
    _pendingRequest = null;
    codeController.clear();
    reviewCodeController.clear();
    value = const SignInModel();
  }

  /// Starts (or restarts) the "Resend code" cooldown, ticking
  /// [SignInModel.secondsRemaining] down to zero one second at a time.
  void _startCooldown() {
    _cooldownTimer?.cancel();
    value = value.copyWith(secondsRemaining: _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = value.secondsRemaining - 1;
      if (next <= 0) {
        timer.cancel();
        value = value.copyWith(secondsRemaining: 0);
      } else {
        value = value.copyWith(secondsRemaining: next);
      }
    });
  }

  /// Starts a passkey sign-in.
  Future<void> signInWithPasskey() => _guarded(_auth.signInWithPasskey);

  /// Starts an Apple sign-in.
  Future<void> signInWithApple() =>
      _guarded(() => _auth.signInWithOAuth(OAuthProvider.apple));

  /// Starts a Google sign-in.
  Future<void> signInWithGoogle() =>
      _guarded(() => _auth.signInWithOAuth(OAuthProvider.google));

  /// Moves to the App Review demo code step — see `apps/app/README.md`'s
  /// "App Review demo access" section for why this is a shared code, not
  /// an email or password: this template has no password sign-in at all
  /// (see `AuthService.signInWithReviewCode`'s dartdoc), and the reviewer
  /// has no inbox for an OTP either. A no-op unless
  /// `AppConfig.reviewDemoEnabled` is set — matches [showReviewerButton]
  /// already gating whether this is ever reachable.
  void continueAsReviewer() {
    if (!_config.reviewDemoEnabled) return;
    reviewCodeController.clear();
    value = value.copyWith(step: SignInStep.reviewCode, error: null);
  }

  /// Exchanges the entered code for a session on the App Review demo
  /// account and, if correct, completes sign-in. Never sends an email or
  /// password — [AuthService.signInWithReviewCode] takes only the code,
  /// so this can only ever authenticate as the one account the backend
  /// itself allow-lists, never an arbitrary one.
  Future<void> submitReviewCode() async {
    if (!_config.reviewDemoEnabled) return;

    value = value.copyWith(submitting: true, error: null);
    try {
      await _auth.signInWithReviewCode(reviewCodeController.text.trim());
      await _completeSignIn();
    } on AuthInvalidCodeError {
      value = value.copyWith(submitting: false, error: SignInError.invalidCode);
    } on AuthError {
      value = value.copyWith(submitting: false, error: SignInError.generic);
    }
  }

  /// Opens the Legal hub.
  void openLegal() => _navigation.push(const LegalHubRoute().location);

  /// Opens the AGB (terms & conditions) legal document.
  void openAgb() => _navigation.push(const AgbRoute().location);

  /// Opens the Datenschutz (privacy policy) legal document.
  void openDatenschutz() => _navigation.push(const DatenschutzRoute().location);

  Future<void> _guarded(Future<AuthSession> Function() action) async {
    value = value.copyWith(submitting: true, error: null);
    try {
      await action();
      await _completeSignIn();
    } on AuthCancelledError {
      value = value.copyWith(submitting: false);
    } on AuthError {
      value = value.copyWith(submitting: false, error: SignInError.generic);
    }
  }

  Future<void> _completeSignIn() async {
    final location = await resolvePostAuthLocation(
      config: _config,
      preferences: _preferences,
    );
    _navigation.go(location);
  }
}
