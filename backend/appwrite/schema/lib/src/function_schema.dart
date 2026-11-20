/// The build command a deployed function runs by default before the server
/// AOT-compiles it — see `FunctionSchema.commands`.
const String defaultFunctionCommands = 'dart pub get';

/// The default set of execution permission roles — see
/// `FunctionSchema.execute`.
const List<String> defaultFunctionExecute = <String>['users'];

/// The default execution timeout in seconds — see `FunctionSchema.timeout`.
///
/// 30s, not Appwrite's console-default 15s: a cold runtime container (no
/// warm instance yet, e.g. right after a deploy or on a quiet local dev
/// instance) can take noticeably longer than 15s to spin up in practice —
/// found by hand running `delete_account` against a real local stack,
/// where a cold-start execution timed out at exactly 15s with no runtime
/// container ever created in time.
const int defaultFunctionTimeoutSeconds = 30;

/// The `api` Function's cron schedule: a tick every five minutes (the
/// router's `cronTick`), on which it dispatches every due scheduled job.
const String apiCronSchedule = '*/5 * * * *';

/// The most Functions a schema may declare.
///
/// **Why 2:** since 2026-01-08 Appwrite Cloud's Free plan allows 2 Functions
/// per project, and creating a third fails with `403
/// additional_resource_not_allowed`. The template stays on the Free plan
/// (decision of 2026-10-01) for development and for low-revenue clones: all
/// server-side operations are *actions* of the one `api` router Function, and
/// the second slot is `hooks` (public, unauthenticated inbound webhooks,
/// signature-verified per hook and routed by path).
const int maxFunctions = 2;

/// The IDs a schema may use for its Functions: the `api` router and the
/// `hooks` webhook receiver (the Paddle billing webhook).
const Set<String> allowedFunctionIds = <String>{'api', 'hooks'};

/// A deployable Appwrite Function.
class FunctionSchema {
  /// Declares a Function named [name] with ID [id], sourced from [path].
  const FunctionSchema({
    required this.id,
    required this.name,
    required this.runtime,
    required this.entrypoint,
    required this.path,
    this.commands = defaultFunctionCommands,
    this.execute = defaultFunctionExecute,
    this.timeout = defaultFunctionTimeoutSeconds,
    this.schedule = '',
    this.variables = const <String, String>{},
    this.scopes = const <String>[],
  });

  /// The function's ID.
  final String id;

  /// The function's display name.
  final String name;

  /// The Appwrite runtime identifier, e.g. `dart-3.12`.
  ///
  /// The template uses `dart-3.12` for every function, on Appwrite Cloud and
  /// the local stack alike: it is Cloud's newest Dart runtime (Cloud offers
  /// no `dart-3.13`), so one runtime serves both targets.
  ///
  /// A raw [String] rather than `package:dart_appwrite`'s `enums.Runtime`,
  /// which was written when that enum lacked the runtime the template needed
  /// (`dart_appwrite` 29.0.0's enum does now include `dart312`; the raw-string
  /// path in `package:appwrite_tool/src/dart_appwrite_admin.dart` is kept
  /// for now).
  final String runtime;

  /// The entrypoint file inside the deployed bundle, e.g. `lib/main.dart`.
  final String entrypoint;

  /// The function's source directory, relative to the repo root, e.g.
  /// `backend/appwrite/functions/api`.
  final String path;

  /// The build command the server runs after unpacking the deployment.
  final String commands;

  /// Execution permission roles, e.g. `['users']` for any signed-in user.
  final List<String> execute;

  /// Execution timeout in seconds.
  final int timeout;

  /// The cron expression the function is executed on, or the empty string
  /// for none (Appwrite's own representation of "no schedule").
  final String schedule;

  /// Function environment variables to provision (non-secret; secrets are
  /// injected by Appwrite itself — see `backend/appwrite/README.md`).
  final Map<String, String> variables;

  /// The scopes granted to this function's short-lived per-execution API
  /// key (the `x-appwrite-key` header — see `FunctionSchema.runtime`'s
  /// dartdoc). Appwrite requires these to be declared on the function
  /// itself, separately from the caller's own `execute` permission above:
  /// `execute` controls *who may invoke* the function, `scopes` controls
  /// *what the function is allowed to do once running* (found by hand —
  /// `delete_account` returned `general_unauthorized_scope` for its own
  /// `TablesDB`/`Storage`/`Users` calls until this was set).
  final List<String> scopes;
}
