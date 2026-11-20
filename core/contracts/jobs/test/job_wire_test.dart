// Test literals (limits, windows, status codes) and `!` on a value the test
// just made are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'package:jobs/jobs.dart';
import 'package:test/test.dart';

void main() {
  test('a lease survives the wire', () async {
    final queue = FakeJobQueue();
    await queue.enqueue(
      const NewJob(
        type: 'scan',
        payload: {'host': 'example.com'},
        priority: JobPriority.high,
      ),
    );
    final lease = (await queue.claim(
      workerId: 'w',
      leaseFor: const Duration(minutes: 1),
    ))!;

    final decoded = JobWire.decodeLease(JobWire.encodeLease(lease));

    expect(decoded.attempt, lease.attempt);
    expect(decoded.workerId, 'w');
    expect(decoded.job.payload, {'host': 'example.com'});
    expect(decoded.job.priority, JobPriority.high);
    expect(decoded.leaseExpiresAt, lease.leaseExpiresAt);
  });

  test('every error keeps its type and has a status', () {
    for (final error in <JobError>[
      const JobNotFoundError('a'),
      const JobLeaseLostError('b'),
      const JobInvalidError('c'),
      const JobPermissionError('d'),
    ]) {
      final back = JobWire.decodeError(JobWire.encodeError(error));

      expect(back.runtimeType, error.runtimeType);
      expect(back.message, error.message);
      expect(JobWire.statusFor(error), greaterThanOrEqualTo(400));
    }
  });
}
