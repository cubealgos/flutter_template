// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:app/app/active_team_service.dart' as _i751;
import 'package:app/app/backend_module.dart' as _i556;
import 'package:app/app/billing_owner_resolver.dart' as _i929;
import 'package:app/app/config.dart' as _i263;
import 'package:app/app/service_module.dart' as _i174;
import 'package:app/features/onboarding/onboarding_step.dart' as _i838;
import 'package:appwrite/appwrite.dart' as _i317;
import 'package:auth/auth.dart' as _i662;
import 'package:billing/billing.dart' as _i444;
import 'package:data/data.dart' as _i437;
import 'package:flutter/widgets.dart' as _i718;
import 'package:get_it/get_it.dart' as _i174;
import 'package:go_router/go_router.dart' as _i583;
import 'package:injectable/injectable.dart' as _i526;
import 'package:mvc/mvc.dart' as _i998;
import 'package:teams/teams.dart' as _i264;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final backendModule = _$BackendModule();
    final serviceModule = _$ServiceModule();
    gh.lazySingleton<_i317.Client>(() => backendModule.appwriteClient());
    gh.lazySingleton<_i264.FakeTeamBackend>(
      () => backendModule.fakeTeamBackend(),
    );
    gh.lazySingleton<_i718.GlobalKey<_i718.NavigatorState>>(
      () => serviceModule.navigatorKey,
    );
    gh.lazySingleton<_i998.LauncherService>(
      () => serviceModule.launcherService(),
    );
    gh.lazySingleton<_i998.ClipboardService>(
      () => serviceModule.clipboardService(),
    );
    gh.lazySingleton<_i263.AppConfig>(() => serviceModule.appConfig());
    gh.lazySingleton<_i838.OnboardingStepRegistry>(
      () => serviceModule.onboardingStepRegistry(),
    );
    gh.lazySingleton<_i437.UserPreferences>(
      () => backendModule.userPreferences(gh<_i317.Client>()),
    );
    gh.lazySingleton<_i437.VersionPolicy>(
      () => backendModule.versionPolicy(gh<_i317.Client>()),
    );
    gh.lazySingleton<_i437.DocumentRepository>(
      () => backendModule.profileRepository(gh<_i317.Client>()),
    );
    gh.lazySingleton<_i444.Billing>(
      () => backendModule.billing(gh<_i317.Client>()),
    );
    gh.lazySingleton<_i751.ActiveTeamService>(
      () => _i751.ActiveTeamService(gh<_i437.UserPreferences>()),
    );
    gh.lazySingleton<_i583.GoRouter>(
      () => serviceModule.router(gh<_i718.GlobalKey<_i718.NavigatorState>>()),
    );
    gh.lazySingleton<_i998.DialogService>(
      () => serviceModule.dialogService(
        gh<_i718.GlobalKey<_i718.NavigatorState>>(),
      ),
    );
    gh.lazySingleton<_i662.AuthService>(
      () => backendModule.authService(
        gh<_i317.Client>(),
        gh<_i263.AppConfig>(),
        gh<_i264.FakeTeamBackend>(),
      ),
    );
    gh.lazySingleton<_i264.TeamService>(
      () => backendModule.teamService(
        gh<_i317.Client>(),
        gh<_i662.AuthService>(),
        gh<_i264.FakeTeamBackend>(),
      ),
    );
    gh.lazySingleton<_i998.NavigationService>(
      () => serviceModule.navigationService(gh<_i583.GoRouter>()),
    );
    gh.lazySingleton<_i929.BillingOwnerResolver>(
      () => _i929.BillingOwnerResolver(
        gh<_i662.AuthService>(),
        gh<_i264.TeamService>(),
        gh<_i751.ActiveTeamService>(),
      ),
    );
    return this;
  }
}

class _$BackendModule extends _i556.BackendModule {}

class _$ServiceModule extends _i174.ServiceModule {}
