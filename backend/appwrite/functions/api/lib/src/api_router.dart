import 'package:api/src/action_context.dart';
import 'package:api/src/api_action.dart';
import 'package:api/src/function_response.dart';
import 'package:api/src/scheduled_job.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// 400: the body is not a JSON object with a string `action`.
const int invalidRequestStatusCode = 400;

/// 401: the action needs a signed-in caller and there is none.
const int unauthenticatedStatusCode = 401;

/// 404: no action is registered under the requested name.
const int unknownActionStatusCode = 404;

/// 500: the action threw unexpectedly.
const int internalErrorStatusCode = 500;

/// 200: scheduled jobs were dispatched.
const int okStatusCode = 200;

/// The key in the request body naming the action.
const String actionKey = 'action';

/// The cron tick the Function is scheduled with, in minutes - see
/// `apiCronSchedule` in `backend/appwrite/schema` for the cron expression
/// this mirrors.
const Duration cronTick = Duration(minutes: 5);

/// Dispatches `{"action": "...", ...}` requests to registered
/// [ApiAction]s, and cron ticks to [ScheduledJob]s.
///
/// The router authenticates (an action's `requiresUser`), dispatches and
/// maps errors - nothing else; validating an action's own fields is that
/// action's job. Independent of the Appwrite runtime's untyped `context` so
/// it is directly unit-testable.
class ApiRouter {
  /// Creates a router over [actions] and [jobs].
  ///
  /// Throws [ArgumentError] on a duplicate action name.
  ApiRouter({
    required Iterable<ApiAction> actions,
    required this.jobs,
    this.log,
  }) : _actions = _byName(actions);

  /// The scheduled jobs; `scheduledJobs` in `registry.dart`. Required, so
  /// `main.dart` can never forget to wire them.
  final List<ScheduledJob> jobs;

  /// Error logging sink (`context.error` in production), if any.
  final void Function(String message)? log;

  final Map<String, ApiAction> _actions;

  /// The registered action names.
  Iterable<String> get actionNames => _actions.keys;

  static Map<String, ApiAction> _byName(Iterable<ApiAction> actions) {
    final byName = <String, ApiAction>{};
    for (final action in actions) {
      if (byName.containsKey(action.name)) {
        throw ArgumentError('Duplicate api action "${action.name}".');
      }
      byName[action.name] = action;
    }

    return byName;
  }

  /// Handles one HTTP execution.
  ///
  /// [rawBody] is the parsed request body (anything - validated here);
  /// [callerUserId] comes from the `x-appwrite-user-id` header. [client] and
  /// [environment] are passed through to the action's `ActionContext`.
  // The execution's four inputs plus the caller address; grouping them into
  // a parameter object would only move the same five names elsewhere.
  // ignore: solid_lints/number_of_parameters
  Future<FunctionResponse> handle({
    required Object? rawBody,
    required String? callerUserId,
    required Client client,
    required Map<String, String> environment,
    String? callerAddress,
  }) async {
    final caller = (callerUserId == null || callerUserId.isEmpty)
        ? null
        : callerUserId;
    final name = _nameOf(rawBody);
    if (name == null) {
      return _error(
        invalidRequestStatusCode,
        'The request body must be a JSON object with a string "$actionKey".',
      );
    }
    final action = _actions[name];
    if (action == null) {
      return _error(unknownActionStatusCode, 'Unknown action "$name".');
    }
    if (action.requiresUser && caller == null) {
      return _error(
        unauthenticatedStatusCode,
        'The "$name" action must be called by an authenticated user.',
      );
    }

    return await _run(
      action,
      ActionContext(
        callerUserId: caller,
        body: _fieldsOf(rawBody),
        environment: environment,
        client: client,
        callerAddress: callerAddress,
        log: log,
      ),
    );
  }

  static String? _nameOf(Object? rawBody) {
    final name = rawBody is Map ? rawBody[actionKey] : null;

    return name is String ? name : null;
  }

  /// [rawBody] without the router's own `action` key (and any non-string
  /// keys, which JSON cannot produce).
  static Map<String, dynamic> _fieldsOf(Object? rawBody) => <String, dynamic>{
    if (rawBody is Map)
      for (final entry in rawBody.entries)
        if (entry.key is String && entry.key != actionKey)
          '${entry.key}': entry.value,
  };

  Future<FunctionResponse> _run(ApiAction action, ActionContext context) async {
    try {
      return await action.run(context);
    } on Exception catch (e) {
      log?.call('${action.name} failed for user "${context.callerUserId}": $e');

      return _error(internalErrorStatusCode, action.failureMessage);
    }
  }

  /// Handles one cron tick at [now]: runs every job that is due, each in
  /// isolation (one failing job never stops the others).
  Future<FunctionResponse> tick({
    required DateTime now,
    required Client client,
    required Map<String, String> environment,
    Duration tickLength = cronTick,
  }) async {
    final context = ActionContext(
      callerUserId: null,
      body: const <String, dynamic>{},
      environment: environment,
      client: client,
      log: log,
    );
    final ran = <String>[];
    final failed = <String>[];
    for (final job in jobs) {
      if (!isDue(job, now: now, tick: tickLength)) continue;
      final slot = now.millisecondsSinceEpoch ~/ job.interval.inMilliseconds;
      try {
        await job.run(context, slot: slot);
        ran.add(job.name);
      } on Exception catch (e) {
        log?.call('scheduled job ${job.name} failed: $e');
        failed.add(job.name);
      }
    }

    return FunctionResponse(
      body: <String, dynamic>{'ran': ran, 'failed': failed},
      statusCode: okStatusCode,
    );
  }

  FunctionResponse _error(int statusCode, String message) => FunctionResponse(
    body: <String, dynamic>{'error': message},
    statusCode: statusCode,
  );
}
