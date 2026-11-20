// Test literals (limits, windows, status codes) and `!` on a value the test
// just made are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'package:jobs/jobs.dart';
import 'package:test/test.dart';

const _lease = Duration(minutes: 1);

void main() {
  test('claims by priority band, then oldest first', () async {
    final queue = FakeJobQueue();
    await queue.enqueue(const NewJob(type: 'a', priority: JobPriority.low));
    queue.advance(const Duration(seconds: 1));
    final normalOld = await queue.enqueue(const NewJob(type: 'a'));
    queue.advance(const Duration(seconds: 1));
    await queue.enqueue(const NewJob(type: 'a'));
    queue.advance(const Duration(seconds: 1));
    final high = await queue.enqueue(
      const NewJob(type: 'a', priority: JobPriority.high),
    );

    final order = <String>[];
    for (var i = 0; i < 3; i++) {
      order.add((await queue.claim(workerId: 'w', leaseFor: _lease))!.job.id);
    }

    expect(order.first, high.id);
    expect(order[1], normalOld.id);
  });

  test('a job is not claimable before its availableAt, nor by a worker of '
      'another type', () async {
    final queue = FakeJobQueue();
    await queue.enqueue(
      NewJob(type: 'scan', availableAt: DateTime.utc(2026, 1, 1, 1)),
    );

    expect(await queue.claim(workerId: 'w', leaseFor: _lease), isNull);
    queue.advance(const Duration(hours: 2));
    expect(
      await queue.claim(workerId: 'w', leaseFor: _lease, types: {'pdf'}),
      isNull,
    );
    expect(
      await queue.claim(workerId: 'w', leaseFor: _lease, types: {'scan'}),
      isNotNull,
    );
  });

  test('a double claim: of concurrent claimers exactly one wins', () async {
    final queue = FakeJobQueue();
    await queue.enqueue(const NewJob(type: 'a'));
    final others = [for (var i = 0; i < 4; i++) queue.sharing()];

    final results = await Future.wait([
      for (var i = 0; i < others.length; i++)
        others[i].claim(workerId: 'w$i', leaseFor: _lease),
    ]);

    expect(results.whereType<JobLease>(), hasLength(1));
    expect(queue.memory.claims, hasLength(1));
  });

  test(
    'a crash: an expired lease returns the job, as the next attempt',
    () async {
      final queue = FakeJobQueue();
      final job = await queue.enqueue(const NewJob(type: 'a'));
      final first = await queue.claim(workerId: 'w1', leaseFor: _lease);
      expect(await queue.claim(workerId: 'w2', leaseFor: _lease), isNull);

      queue.advance(const Duration(minutes: 2));
      final second = await queue.claim(workerId: 'w2', leaseFor: _lease);

      expect(first!.attempt, 1);
      expect(second!.attempt, 2);
      expect(second.job.id, job.id);
    },
  );

  test('a heartbeat keeps the lease alive past its first expiry', () async {
    final queue = FakeJobQueue();
    await queue.enqueue(const NewJob(type: 'a'));
    var lease = (await queue.claim(workerId: 'w1', leaseFor: _lease))!;

    queue.advance(const Duration(seconds: 50));
    lease = await queue.heartbeat(lease, leaseFor: _lease);
    queue.advance(const Duration(seconds: 50));

    expect(await queue.claim(workerId: 'w2', leaseFor: _lease), isNull);
    expect(await queue.status(lease.job.id), JobStatus.running);
  });

  test('a stale write: a worker that lost its lease is rejected', () async {
    final queue = FakeJobQueue();
    await queue.enqueue(const NewJob(type: 'a'));
    final stale = (await queue.claim(workerId: 'w1', leaseFor: _lease))!;
    queue.advance(const Duration(minutes: 2));
    final current = (await queue.claim(workerId: 'w2', leaseFor: _lease))!;

    await expectLater(
      queue.complete(stale, result: {'x': 1}),
      throwsA(isA<JobLeaseLostError>()),
    );
    await expectLater(
      queue.heartbeat(stale, leaseFor: _lease),
      throwsA(isA<JobLeaseLostError>()),
    );
    await expectLater(
      queue.fail(stale, error: 'late'),
      throwsA(isA<JobLeaseLostError>()),
    );
    expect(await queue.status(stale.job.id), JobStatus.running);

    await queue.complete(current, result: {'x': 2});
    expect(await queue.status(stale.job.id), JobStatus.succeeded);
  });

  test('a stale completion that raced the takeover is rejected and does not '
      'count', () async {
    final store = _TakeoverBeforeUpdate();
    final queue = FakeJobQueue(store: store);
    await queue.enqueue(const NewJob(type: 'a'));
    final stale = (await queue.claim(workerId: 'w1', leaseFor: _lease))!;
    queue.advance(const Duration(minutes: 2));
    // The takeover lands after the stale worker's check, before its write.
    store.beforeUpdate = () async {
      await queue.sharing().claim(workerId: 'w2', leaseFor: _lease);
    };

    await expectLater(queue.complete(stale), throwsA(isA<JobLeaseLostError>()));
    expect(await queue.status(stale.job.id), JobStatus.running);
  });

  test(
    'fail requeues until the attempts run out, then the job is dead',
    () async {
      final queue = FakeJobQueue();
      final job = await queue.enqueue(const NewJob(type: 'a', maxAttempts: 2));

      await queue.fail(
        (await queue.claim(workerId: 'w', leaseFor: _lease))!,
        error: 'boom',
      );
      expect(await queue.status(job.id), JobStatus.queued);
      await queue.fail(
        (await queue.claim(workerId: 'w', leaseFor: _lease))!,
        error: 'boom',
      );

      expect(await queue.status(job.id), JobStatus.dead);
      expect(await queue.claim(workerId: 'w', leaseFor: _lease), isNull);
    },
  );

  test('repeated crashes also exhaust the attempts', () async {
    final queue = FakeJobQueue();
    final job = await queue.enqueue(const NewJob(type: 'a', maxAttempts: 2));

    for (var i = 0; i < 2; i++) {
      await queue.claim(workerId: 'w', leaseFor: _lease);
      queue.advance(const Duration(minutes: 2));
    }

    expect(await queue.status(job.id), JobStatus.dead);
    expect(await queue.claim(workerId: 'w', leaseFor: _lease), isNull);
  });

  test('release gives the job back without using up an attempt', () async {
    final queue = FakeJobQueue();
    final job = await queue.enqueue(const NewJob(type: 'a', maxAttempts: 1));

    await queue.release((await queue.claim(workerId: 'w', leaseFor: _lease))!);
    expect(await queue.status(job.id), JobStatus.queued);
    final again = await queue.claim(workerId: 'w', leaseFor: _lease);

    expect(again!.attempt, 2);
  });

  test('a finished job cannot be completed twice', () async {
    final queue = FakeJobQueue();
    await queue.enqueue(const NewJob(type: 'a'));
    final lease = (await queue.claim(workerId: 'w', leaseFor: _lease))!;
    await queue.complete(lease);

    await expectLater(queue.complete(lease), throwsA(isA<JobLeaseLostError>()));
    expect(await queue.claim(workerId: 'w', leaseFor: _lease), isNull);
  });

  test('another worker cannot use a lease it was not given', () async {
    final queue = FakeJobQueue();
    await queue.enqueue(const NewJob(type: 'a'));
    final lease = (await queue.claim(workerId: 'w1', leaseFor: _lease))!;
    final forged = JobLease(
      job: lease.job,
      attempt: lease.attempt,
      workerId: 'w2',
      leaseExpiresAt: lease.leaseExpiresAt,
    );

    await expectLater(
      queue.complete(forged),
      throwsA(isA<JobLeaseLostError>()),
    );
  });

  test(
    'rejects a job with no type or no attempts; unknown status id',
    () async {
      final queue = FakeJobQueue();

      await expectLater(
        queue.enqueue(const NewJob(type: ' ')),
        throwsA(isA<JobInvalidError>()),
      );
      await expectLater(
        queue.enqueue(const NewJob(type: 'a', maxAttempts: 0)),
        throwsA(isA<JobInvalidError>()),
      );
      await expectLater(queue.status('nope'), throwsA(isA<JobNotFoundError>()));
    },
  );

  test(
    'a crash between inserting a claim and caching it loses nothing',
    () async {
      final queue = FakeJobQueue();
      final job = await queue.enqueue(const NewJob(type: 'a'));
      // The claim row was written, the cache update never happened.
      await queue.memory.insertClaim(
        JobClaim(
          jobId: job.id,
          attempt: 1,
          workerId: 'dead',
          leaseExpiresAt: DateTime.utc(2026, 1, 1, 0, 1),
        ),
      );

      expect(await queue.claim(workerId: 'w', leaseFor: _lease), isNull);
      queue.advance(const Duration(minutes: 2));
      final lease = await queue.claim(workerId: 'w', leaseFor: _lease);

      expect(lease!.attempt, 2);
    },
  );
}

class _TakeoverBeforeUpdate extends InMemoryJobStore {
  Future<void> Function()? beforeUpdate;

  @override
  Future<void> updateClaim(JobClaim claim) async {
    final hook = beforeUpdate;
    beforeUpdate = null;
    if (hook != null) await hook();
    await super.updateClaim(claim);
  }
}
