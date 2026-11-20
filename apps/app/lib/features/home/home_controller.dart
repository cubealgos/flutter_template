import 'dart:async';

import 'package:app/app/preference_keys.dart';
import 'package:app/app/router.dart';
import 'package:app/features/home/home_model.dart';
import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:app/features/permission_pre_prompt/permission_kind.dart';
import 'package:app/features/permission_pre_prompt/permission_pre_prompt_view.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:mvc/mvc.dart';

/// Drives `HomeView`: the signed-in landing screen. Shows the push
/// notification `PermissionPrePromptView` once, in context, the first
/// time Home is reached — never on every visit (tracked via
/// [pushPermissionPromptShownPreferenceKey]) — and computes the "Finish
/// your setup" card's contents from the same [onboardingSteps] the
/// onboarding stepper itself walks through.
class HomeController extends ViewController<HomeModel> {
  /// Creates the controller with every service it needs injected, plus
  /// [onboardingSteps] — the per-app step list (see
  /// `OnboardingStepRegistry`), read-only here.
  HomeController(
    this._navigation,
    this._auth,
    this._dialogService,
    this._preferences, {
    required this.onboardingSteps,
  }) : super(const HomeModel());

  final NavigationService _navigation;
  final AuthService _auth;
  final DialogService _dialogService;
  final UserPreferences _preferences;

  /// The same per-app onboarding step list `OnboardingController` walks
  /// through — used only to know each open step's title and how many
  /// steps exist in total.
  final List<OnboardingStep> onboardingSteps;

  /// Whether the "Finish your setup" card should render: not while the
  /// initial read is still in flight, not once dismissed this session, and
  /// only while at least one onboarding step is still open.
  bool get showSetupCard =>
      !value.loadingSetupProgress &&
      !value.setupCardDismissed &&
      value.openSteps.isNotEmpty;

  @override
  void init() {
    unawaited(_loadSetupProgress());
    unawaited(_maybeShowPushPermissionPrompt());
  }

  /// Opens Settings.
  void openSettings() => _navigation.push(const SettingsHubRoute().location);

  /// Opens the onboarding stepper — it resumes at the first open step on
  /// its own (`OnboardingController._resume`), so every card row and the
  /// card itself all lead here alike.
  void openOnboarding() => _navigation.push(const OnboardingRoute().location);

  /// Hides the setup card for the rest of this session.
  void dismissSetupCard() {
    value = value.copyWith(setupCardDismissed: true);
  }

  /// Signs out and returns to sign-in.
  Future<void> signOut() async {
    await _auth.signOut();
    _navigation.go(const SignInRoute().location);
  }

  Future<void> _loadSetupProgress() async {
    final prefs = await _preferences.getAll();
    final status = decodeOnboardingStepStatus(
      prefs[onboardingStepStatusPreferenceKey],
    );
    final completed = onboardingSteps
        .where((step) => status[step.id] == OnboardingStepStatus.completed)
        .length;
    final open = onboardingSteps
        .where((step) => status[step.id] != OnboardingStepStatus.completed)
        .map((step) => (id: step.id, title: step.title))
        .toList();

    value = value.copyWith(
      loadingSetupProgress: false,
      completedStepCount: completed,
      totalStepCount: onboardingSteps.length,
      openSteps: open,
    );
  }

  Future<void> _maybeShowPushPermissionPrompt() async {
    final prefs = await _preferences.getAll();
    if (prefs[pushPermissionPromptShownPreferenceKey] == true) return;

    await _preferences.update(<String, dynamic>{
      pushPermissionPromptShownPreferenceKey: true,
    });
    await _dialogService.show(
      (_) => PermissionPrePromptView(
        kind: PermissionKind.push,
        // A real app requests the actual platform permission here (see
        // PermissionPrePromptView's dartdoc) — this template adds no
        // platform-permission package dependency, so there's deliberately
        // nothing to call yet.
        // ignore: solid_lints/no_empty_block
        onContinue: () {},
      ),
    );
  }
}
