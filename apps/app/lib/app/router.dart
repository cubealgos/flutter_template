// This file's path (`apps/app/lib/app/router.dart`) and its `router.g.dart`
// part are fixed by the app codegen wiring — see CLAUDE.md's "Workspace
// layout" row — so a route class can't be renamed to match the file name.
// ignore_for_file: solid_lints/prefer_match_file_name
import 'package:app/features/bootstrap/bootstrap_view.dart';
import 'package:app/features/consent/consent_view.dart';
import 'package:app/features/home/home_view.dart';
import 'package:app/features/legal/document/legal_document_type.dart';
import 'package:app/features/legal/document/legal_document_view.dart';
import 'package:app/features/legal/legal_hub_view.dart';
import 'package:app/features/legal/licences/licences_view.dart';
import 'package:app/features/onboarding/onboarding_view.dart';
import 'package:app/features/settings/account/account_settings_view.dart';
import 'package:app/features/settings/paywall/paywall_view.dart';
import 'package:app/features/settings/privacy/privacy_settings_view.dart';
import 'package:app/features/settings/settings_hub_view.dart';
import 'package:app/features/settings/teams/members/members_view.dart';
import 'package:app/features/settings/teams/teams_view.dart';
import 'package:app/features/sign_in/sign_in_view.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

part 'router.g.dart';

/// Every route in the app, declared flat (full paths, no nested
/// `routes:`) so each path is self-evident from its own annotation rather
/// than assembled from ancestors — see the plan's "Default screens"
/// section for what each screen does.
///
/// `go_router_builder` aggregates every `@TypedGoRoute`-annotated class
/// reachable from this annotation into the generated `$appRoutes` list (in
/// `router.g.dart`), which `ServiceModule.router` passes to `GoRouter`. A
/// controller never references `GoRouter`/`go_router` itself — it reaches
/// a typed route's `.location` through the injected `NavigationService`;
/// only this file and `service_module.dart` may import `package:go_router`,
/// per `core/architecture/mvc_lints`' view-boundary rules.
@TypedGoRoute<BootstrapRoute>(
  path: '/',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<SignInRoute>(path: 'sign-in'),
    TypedGoRoute<ConsentRoute>(path: 'consent'),
    TypedGoRoute<OnboardingRoute>(path: 'onboarding'),
    TypedGoRoute<HomeRoute>(path: 'home'),
    TypedGoRoute<LegalHubRoute>(path: 'legal'),
    TypedGoRoute<ImpressumRoute>(path: 'legal/impressum'),
    TypedGoRoute<DatenschutzRoute>(path: 'legal/datenschutz'),
    TypedGoRoute<AgbRoute>(path: 'legal/agb'),
    TypedGoRoute<BarrierefreiheitRoute>(path: 'legal/barrierefreiheit'),
    TypedGoRoute<LicencesRoute>(path: 'legal/licences'),
    TypedGoRoute<SettingsHubRoute>(path: 'settings'),
    TypedGoRoute<PrivacySettingsRoute>(path: 'settings/privacy'),
    TypedGoRoute<AccountSettingsRoute>(path: 'settings/account'),
    TypedGoRoute<PaywallRoute>(path: 'settings/paywall'),
    TypedGoRoute<TeamsRoute>(path: 'settings/teams'),
    TypedGoRoute<MembersRoute>(path: 'settings/teams/members'),
  ],
)
class BootstrapRoute extends GoRouteData with $BootstrapRoute {
  /// Creates the bootstrap/splash route.
  const BootstrapRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BootstrapView();
}

/// The email-first sign-in route, pre-login.
class SignInRoute extends GoRouteData with $SignInRoute {
  /// Creates the sign-in route.
  const SignInRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => SignInView();
}

/// The consent-sheet route (Accept/Reject, nothing pre-ticked).
class ConsentRoute extends GoRouteData with $ConsentRoute {
  /// Creates the consent route.
  const ConsentRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => ConsentView();
}

/// The onboarding route: empty states plus a dismissible checklist.
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  /// Creates the onboarding route.
  const OnboardingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => OnboardingView();
}

/// The signed-in landing screen.
class HomeRoute extends GoRouteData with $HomeRoute {
  /// Creates the home route.
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => HomeView();
}

/// The Legal hub — reachable in one tap from [SignInRoute] and
/// [SettingsHubRoute], pre-login.
class LegalHubRoute extends GoRouteData with $LegalHubRoute {
  /// Creates the legal hub route.
  const LegalHubRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => LegalHubView();
}

/// The Impressum (§ 5 DDG) legal document.
class ImpressumRoute extends GoRouteData with $ImpressumRoute {
  /// Creates the Impressum route.
  const ImpressumRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      LegalDocumentView(type: LegalDocumentType.impressum);
}

/// The Datenschutz (privacy policy) legal document.
class DatenschutzRoute extends GoRouteData with $DatenschutzRoute {
  /// Creates the Datenschutz route.
  const DatenschutzRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      LegalDocumentView(type: LegalDocumentType.datenschutz);
}

/// The AGB (terms & conditions) legal document.
class AgbRoute extends GoRouteData with $AgbRoute {
  /// Creates the AGB route.
  const AgbRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      LegalDocumentView(type: LegalDocumentType.agb);
}

/// The Barrierefreiheit (accessibility statement) legal document — only
/// linked from [LegalHubView] when `AppConfig.accessibilityStatement` is
/// on, but always routable.
class BarrierefreiheitRoute extends GoRouteData with $BarrierefreiheitRoute {
  /// Creates the Barrierefreiheit route.
  const BarrierefreiheitRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      LegalDocumentView(type: LegalDocumentType.barrierefreiheit);
}

/// The OSS licences page, built from `LicenseRegistry.licenses`.
class LicencesRoute extends GoRouteData with $LicencesRoute {
  /// Creates the licences route.
  const LicencesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => LicencesView();
}

/// The Settings hub, post-login.
class SettingsHubRoute extends GoRouteData with $SettingsHubRoute {
  /// Creates the settings hub route.
  const SettingsHubRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => SettingsHubView();
}

/// Settings → Privacy: change consent, export data with step-up.
class PrivacySettingsRoute extends GoRouteData with $PrivacySettingsRoute {
  /// Creates the privacy settings route.
  const PrivacySettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PrivacySettingsView();
}

/// Settings → Account: disconnect social identities, delete account.
class AccountSettingsRoute extends GoRouteData with $AccountSettingsRoute {
  /// Creates the account settings route.
  const AccountSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      AccountSettingsView();
}

/// The subscription screen (web billing), only reachable through UI gated on
/// `AppConfig.paywall` (the route itself is always registered).
class PaywallRoute extends GoRouteData with $PaywallRoute {
  /// Creates the paywall route.
  const PaywallRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => PaywallView();
}

/// The Teams route.
class TeamsRoute extends GoRouteData with $TeamsRoute {
  /// Creates the Teams route.
  const TeamsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => TeamsView();
}

/// The Members route.
class MembersRoute extends GoRouteData with $MembersRoute {
  /// Creates the Members route.
  const MembersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => MembersView();
}
