import 'package:jobs/src/in_memory_job_store.dart';
import 'package:jobs/src/job_queue_engine.dart';

/// An in-memory [JobQueueEngine] with a clock a test moves by hand.
///
/// Several `FakeJobQueue`s over one [store] are several workers (or
/// Function executions) sharing one queue.
class FakeJobQueue extends JobQueueEngine {
  /// Creates a queue over [store] (a fresh one by default), starting at
  /// [start] (2026-01-01 UTC by default).
  FakeJobQueue({InMemoryJobStore? store, DateTime? start})
    : this._(store ?? InMemoryJobStore(), _Time(start));

  FakeJobQueue._(InMemoryJobStore store, this._time)
    : memory = store,
      super(store: store, newId: _time.nextId, clock: _time.now);

  /// The store, to assert on claims.
  final InMemoryJobStore memory;

  final _Time _time;

  /// Moves the clock forward by [by].
  void advance(Duration by) => _time.advance(by);

  /// Another view of the same queue: same store and same clock, so its calls
  /// race with this one's.
  FakeJobQueue sharing() => FakeJobQueue._(memory, _time);
}

class _Time {
  _Time(DateTime? start) : _now = (start ?? DateTime.utc(2026)).toUtc();

  DateTime _now;
  int _ids = 0;

  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);

  String nextId() => 'job-${_ids++}';
}
