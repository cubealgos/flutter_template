// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$bootstrapRoute];

RouteBase get $bootstrapRoute => GoRouteData.$route(
  path: '/',
  hasOverriddenOnExit: false,
  factory: $BootstrapRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'sign-in',
      hasOverriddenOnExit: false,
      factory: $SignInRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'consent',
      hasOverriddenOnExit: false,
      factory: $ConsentRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'onboarding',
      hasOverriddenOnExit: false,
      factory: $OnboardingRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'home',
      hasOverriddenOnExit: false,
      factory: $HomeRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'legal',
      hasOverriddenOnExit: false,
      factory: $LegalHubRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'legal/impressum',
      hasOverriddenOnExit: false,
      factory: $ImpressumRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'legal/datenschutz',
      hasOverriddenOnExit: false,
      factory: $DatenschutzRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'legal/agb',
      hasOverriddenOnExit: false,
      factory: $AgbRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'legal/barrierefreiheit',
      hasOverriddenOnExit: false,
      factory: $BarrierefreiheitRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'legal/licences',
      hasOverriddenOnExit: false,
      factory: $LicencesRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'settings',
      hasOverriddenOnExit: false,
      factory: $SettingsHubRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'settings/privacy',
      hasOverriddenOnExit: false,
      factory: $PrivacySettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'settings/account',
      hasOverriddenOnExit: false,
      factory: $AccountSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'settings/paywall',
      hasOverriddenOnExit: false,
      factory: $PaywallRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'settings/teams',
      hasOverriddenOnExit: false,
      factory: $TeamsRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'settings/teams/members',
      hasOverriddenOnExit: false,
      factory: $MembersRoute._fromState,
    ),
  ],
);

mixin $BootstrapRoute on GoRouteData {
  static BootstrapRoute _fromState(GoRouterState state) =>
      const BootstrapRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SignInRoute on GoRouteData {
  static SignInRoute _fromState(GoRouterState state) => const SignInRoute();

  @override
  String get location => GoRouteData.$location('/sign-in');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ConsentRoute on GoRouteData {
  static ConsentRoute _fromState(GoRouterState state) => const ConsentRoute();

  @override
  String get location => GoRouteData.$location('/consent');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $OnboardingRoute on GoRouteData {
  static OnboardingRoute _fromState(GoRouterState state) =>
      const OnboardingRoute();

  @override
  String get location => GoRouteData.$location('/onboarding');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/home');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $LegalHubRoute on GoRouteData {
  static LegalHubRoute _fromState(GoRouterState state) => const LegalHubRoute();

  @override
  String get location => GoRouteData.$location('/legal');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ImpressumRoute on GoRouteData {
  static ImpressumRoute _fromState(GoRouterState state) =>
      const ImpressumRoute();

  @override
  String get location => GoRouteData.$location('/legal/impressum');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DatenschutzRoute on GoRouteData {
  static DatenschutzRoute _fromState(GoRouterState state) =>
      const DatenschutzRoute();

  @override
  String get location => GoRouteData.$location('/legal/datenschutz');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AgbRoute on GoRouteData {
  static AgbRoute _fromState(GoRouterState state) => const AgbRoute();

  @override
  String get location => GoRouteData.$location('/legal/agb');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $BarrierefreiheitRoute on GoRouteData {
  static BarrierefreiheitRoute _fromState(GoRouterState state) =>
      const BarrierefreiheitRoute();

  @override
  String get location => GoRouteData.$location('/legal/barrierefreiheit');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $LicencesRoute on GoRouteData {
  static LicencesRoute _fromState(GoRouterState state) => const LicencesRoute();

  @override
  String get location => GoRouteData.$location('/legal/licences');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SettingsHubRoute on GoRouteData {
  static SettingsHubRoute _fromState(GoRouterState state) =>
      const SettingsHubRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PrivacySettingsRoute on GoRouteData {
  static PrivacySettingsRoute _fromState(GoRouterState state) =>
      const PrivacySettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/privacy');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountSettingsRoute on GoRouteData {
  static AccountSettingsRoute _fromState(GoRouterState state) =>
      const AccountSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/account');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PaywallRoute on GoRouteData {
  static PaywallRoute _fromState(GoRouterState state) => const PaywallRoute();

  @override
  String get location => GoRouteData.$location('/settings/paywall');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $TeamsRoute on GoRouteData {
  static TeamsRoute _fromState(GoRouterState state) => const TeamsRoute();

  @override
  String get location => GoRouteData.$location('/settings/teams');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MembersRoute on GoRouteData {
  static MembersRoute _fromState(GoRouterState state) => const MembersRoute();

  @override
  String get location => GoRouteData.$location('/settings/teams/members');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
