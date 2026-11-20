import 'package:api/src/action_context.dart';

/// Periodic work the `api` Function runs from its cron tick.
///
/// The Function has one cron schedule (`FunctionSchema.schedule`, a tick
/// every few minutes); each job declares its own [interval] and the router
/// runs it when a slot boundary fell inside the last tick. A tick can be
/// delivered twice or late, so [run] must be idempotent per slot - the `slot`
/// argument identifies it.
abstract interface class ScheduledJob {
  /// A stable name for logs.
  String get name;

  /// How often the job runs; at least the cron tick.
  Duration get interval;

  /// The Appwrite API-key scopes this job needs; counted into the
  /// Function's scope union like an action's.
  Set<String> get scopes;

  /// Runs the job for `slot` (`now` in whole intervals since the epoch).
  Future<void> run(ActionContext context, {required int slot});
}

/// Whether [job] is due on a tick at [now] that follows a tick [tick] ago:
/// true when a slot boundary of [ScheduledJob.interval] lies in
/// `(now - tick, now]`.
bool isDue(ScheduledJob job, {required DateTime now, required Duration tick}) {
  final interval = job.interval.inMilliseconds;
  final current = now.millisecondsSinceEpoch ~/ interval;
  final previous = now.subtract(tick).millisecondsSinceEpoch ~/ interval;

  return current != previous;
}
