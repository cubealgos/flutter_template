import 'package:app/app/billing_plans.dart';
import 'package:app/app/config.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:auth/auth.dart';
import 'package:billing/billing.dart';
import 'package:data/data.dart';
import 'package:injectable/injectable.dart';
import 'package:teams/teams.dart';

/// Which backend the app's services talk to —
/// `--dart-define=BACKEND=appwrite|fake`. Defaults to `fake` so every
/// `flutter test` run (which never passes this) and every plain `flutter
/// run` with no defines exercises the in-memory fakes, never a real
/// Appwrite instance, unless a developer opts in explicitly. See
/// `apps/app/README.md`.
const String backendDefine = String.fromEnvironment(
  'BACKEND',
  defaultValue: 'fake',
);

/// Whether [backendDefine] selects the real Appwrite backend.
const bool useAppwriteBackend = backendDefine == 'appwrite';

/// The Appwrite project endpoint — `--dart-define=APPWRITE_ENDPOINT=…`.
/// Only read when [useAppwriteBackend] is true. See `apps/app/README.md`
/// for an Appwrite Cloud endpoint's value.
const String appwriteEndpointDefine = String.fromEnvironment(
  'APPWRITE_ENDPOINT',
);

/// The Appwrite project ID — `--dart-define=APPWRITE_PROJECT_ID=…`.
const String appwriteProjectIdDefine = String.fromEnvironment(
  'APPWRITE_PROJECT_ID',
);

/// A syntactically valid placeholder endpoint [buildAppwriteClient] falls
/// back to when [useAppwriteBackend] is false. `Client.setEndpoint`
/// validates its argument eagerly (throws `AppwriteException` for an
/// empty/invalid URL) — since [BackendModule.appwriteClient] is built
/// unconditionally (see its dartdoc), the fake-backend path (the default —
/// every test, and a plain `flutter run` with no defines) would otherwise
/// crash on a perfectly normal empty `APPWRITE_ENDPOINT` define. This
/// [Client] is never actually used for a network call on that path.
const String placeholderAppwriteEndpoint = 'https://localhost/v1';

/// Builds the app's Appwrite [Client] from the `APPWRITE_ENDPOINT`/
/// `APPWRITE_PROJECT_ID` `--dart-define`s — or, when [useAppwriteBackend] is
/// false, from [placeholderAppwriteEndpoint] (see that constant's dartdoc
/// for why).
Client buildAppwriteClient() {
  const endpoint = useAppwriteBackend
      ? appwriteEndpointDefine
      : placeholderAppwriteEndpoint;

  return Client().setEndpoint(endpoint).setProject(appwriteProjectIdDefine);
}

/// Registers the app's backend-agnostic services
/// ([AuthService]/[DocumentRepository]/[UserPreferences]/[VersionPolicy]),
/// picking the real Appwrite adapters or the in-memory fakes per
/// [useAppwriteBackend].
///
/// Every controller depends on these interfaces (`core/contracts/auth`,
/// `core/contracts/data`), never `AppwriteAuthService`/`FakeAuthService`/etc.
/// directly — same "depend on the interface, inject a fake in tests"
/// pattern as `ServiceModule`'s `mvc` services.
@module
abstract class BackendModule {
  /// The shared Appwrite [Client], built once regardless of
  /// [useAppwriteBackend] — constructing a [Client] does no I/O, so
  /// building it unconditionally keeps this module simple; it's simply
  /// unused when the fakes are selected.
  @lazySingleton
  Client appwriteClient() => buildAppwriteClient();

  /// The app's [AuthService]. [config] is only used to carry
  /// [AppConfig.reviewDemoEnabled] through to [FakeAuthService] (so a fake
  /// backend build's "App Review demo access" shortcut works the same way
  /// as a real one's, via `FakeAuthService.fixedReviewDemoCode`) —
  /// `AppwriteAuthService.signInWithReviewCode` needs no equivalent
  /// wiring: which account it can ever authenticate as is fixed entirely
  /// server-side, by `review_demo_sign_in`'s own function variables.
  ///
  /// On the fake backend, [fakeTeams] makes `deleteAccount` refuse for a
  /// team owner and drop a leaving member's memberships, as the real
  /// `delete_account` action does.
  @lazySingleton
  AuthService authService(
    Client client,
    AppConfig config,
    FakeTeamBackend fakeTeams,
  ) => useAppwriteBackend
      ? AppwriteAuthService(client)
      : FakeAuthService(
          reviewDemoCode: config.reviewDemoEnabled
              ? FakeAuthService.fixedReviewDemoCode
              : null,
          ownedTeamNames: fakeTeams.ownedTeamNames,
          onAccountDeleted: fakeTeams.forgetUser,
        );

  /// The in-memory tenancy state the fake [AuthService] and [TeamService]
  /// share (unused when the Appwrite backend is selected).
  @lazySingleton
  FakeTeamBackend fakeTeamBackend() => FakeTeamBackend();

  /// The app's [UserPreferences] — backs the consent choice and the
  /// onboarding checklist's dismissed state.
  @lazySingleton
  UserPreferences userPreferences(Client client) => useAppwriteBackend
      ? AppwriteUserPreferences(client)
      : FakeUserPreferences();

  /// The app's [VersionPolicy] — the bootstrap/splash screen's
  /// min-version check.
  @lazySingleton
  VersionPolicy versionPolicy(Client client) =>
      useAppwriteBackend ? AppwriteVersionPolicy(client) : FakeVersionPolicy();

  /// The [DocumentRepository] for `templateSchema`'s `profiles` table —
  /// the one collection Settings → Privacy's data-export screen reads.
  @lazySingleton
  DocumentRepository profileRepository(Client client) => useAppwriteBackend
      ? AppwriteDocumentRepository(
          client,
          databaseId: templateSchema.databaseId,
          tableId: 'profiles',
        )
      : FakeDocumentRepository();

  /// The app's [TeamService]: Appwrite Teams behind the `team_admin`
  /// Function, or an in-memory fake tenancy backend acting as whoever is
  /// signed in to [auth]. See `apps/app/README.md`'s "Teams" section.
  @lazySingleton
  TeamService teamService(
    Client client,
    AuthService auth,
    FakeTeamBackend fakeTeams,
  ) => useAppwriteBackend
      ? AppwriteTeamService(client)
      : fakeTeams.serviceForSession(() async {
          final session = auth.currentSession;
          if (session == null) return null;

          return TeamActor(
            userId: session.userId,
            email: session.email ?? '${session.userId}@fake.invalid',
          );
        });

  /// The app's [Billing]: the `billing` action of the `api` Function, or an
  /// in-memory fake (a checkout charges nothing) on the fake backend. See
  /// `apps/app/README.md`'s "Billing and the paywall".
  @lazySingleton
  Billing billing(Client client) => useAppwriteBackend
      ? AppwriteBilling(client)
      : FakeBilling(plans: <String>{defaultBillingPlan});
}
