import 'package:app/app/config.dart';
import 'package:app/app/router.dart';
import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:app/features/onboarding/steps/default_onboarding_step_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:mvc/mvc.dart';

/// Registers the default implementations of `package:mvc`'s services
/// ([NavigationService], [DialogService], [LauncherService],
/// [ClipboardService]), the [GoRouter] and root [GlobalKey] they share,
/// the app's [AppConfig], and the default [OnboardingStepRegistry].
///
/// A controller depends on the `mvc` interfaces, never these concrete types
/// directly, so a controller test can inject a mock instead of standing up a
/// real router (see `test/features/home/home_controller_test.dart`).
@module
abstract class ServiceModule {
  /// The root navigator key: [router] attaches `GoRouter`'s root
  /// [Navigator] to it, and [dialogService] shows dialogs above that same
  /// [Navigator].
  @lazySingleton
  GlobalKey<NavigatorState> get navigatorKey => GlobalKey<NavigatorState>();

  /// The app's typed [GoRouter], built from the routes `go_router_builder`
  /// generates in `router.g.dart` from `router.dart`'s `@TypedGoRoute`
  /// annotations.
  @lazySingleton
  GoRouter router(GlobalKey<NavigatorState> navigatorKey) =>
      GoRouter(navigatorKey: navigatorKey, routes: $appRoutes);

  /// The default [NavigationService], wrapping [router].
  @lazySingleton
  NavigationService navigationService(GoRouter router) =>
      GoRouterNavigationService(router);

  /// The default [DialogService], showing dialogs above [navigatorKey].
  @lazySingleton
  DialogService dialogService(GlobalKey<NavigatorState> navigatorKey) =>
      OverlayDialogService(navigatorKey);

  /// The default [LauncherService], wrapping `package:url_launcher`.
  @lazySingleton
  LauncherService launcherService() => const UrlLauncherService();

  /// The default [ClipboardService], wrapping
  /// `package:flutter/services.dart`'s `Clipboard`.
  @lazySingleton
  ClipboardService clipboardService() => const SystemClipboardService();

  /// The app's configuration. A clone replaces this placeholder factory
  /// call's field values (or reads them from build-time config) rather than
  /// growing conditionals around `AppConfig()`'s defaults. `appVersion` and
  /// `reviewDemoEnabled` are the two fields sourced from `--dart-define`s
  /// (`APP_VERSION`, `REVIEW_DEMO_ENABLED`) rather than hard-coded — see
  /// `apps/app/README.md`.
  @lazySingleton
  AppConfig appConfig() => AppConfig(
    appVersion: appVersionDefine.isEmpty
        ? const AppConfig().appVersion
        : appVersionDefine,
    // The analyzer sees `reviewDemoEnabledDefine` as always `false` here
    // (no `--dart-define` is ever passed during analysis, only at a real
    // build), so it reads this as matching `AppConfig.reviewDemoEnabled`'s
    // own `false` default and flags it "redundant" - a real build with
    // `--dart-define=REVIEW_DEMO_ENABLED=true` genuinely differs, which is
    // the entire point of passing it through explicitly rather than
    // relying on the default.
    // ignore: avoid_redundant_argument_values
    reviewDemoEnabled: reviewDemoEnabledDefine,
  );

  /// The onboarding stepper's per-app step list: a clone
  /// replaces this factory with one returning its own
  /// [OnboardingStepRegistry] implementation — the stepper itself
  /// (`OnboardingController`/`OnboardingView`) never changes.
  @lazySingleton
  OnboardingStepRegistry onboardingStepRegistry() =>
      const DefaultOnboardingStepRegistry();
}

/// The running app's own version — `--dart-define=APP_VERSION=1.2.3` —
/// empty when unset (e.g. every `flutter test` run, which never passes
/// this), which `ServiceModule.appConfig` falls back to `AppConfig`'s own
/// placeholder default for.
const String appVersionDefine = String.fromEnvironment('APP_VERSION');

/// Whether to show the App Review demo shortcut —
/// `--dart-define=REVIEW_DEMO_ENABLED=true`. `false` (never set) for every
/// `flutter test` run and a plain `flutter run`/`flutter build` with no
/// defines — a developer opts a review build into this explicitly, the
/// same "off unless asked for" default `BACKEND`/`APPWRITE_*` follow.
const bool reviewDemoEnabledDefine = bool.fromEnvironment(
  'REVIEW_DEMO_ENABLED',
);
