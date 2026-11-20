import 'package:api/src/action_context.dart';
import 'package:api/src/schedule/appwrite_slot_store.dart';
import 'package:api/src/schedule/slot_store.dart';
import 'package:api/src/scheduled_job.dart';
import 'package:appwrite_schema/appwrite_schema.dart';

/// Builds the store a run uses, over [context]'s client.
typedef SlotStoreFactory = SlotStore Function(ActionContext context);

SlotStore _appwriteSlots(ActionContext context) => AppwriteSlotStore(
  client: context.client,
  databaseId: templateSchema.databaseId,
);

/// Wraps a [ScheduledJob] so each of its slots runs **at most once**, even if
/// Appwrite fires the cron twice or late.
///
/// Before running [inner] it claims the slot (a unique row per job and slot);
/// a run that loses the claim does nothing. If [inner] throws, the claim is
/// released so a re-delivered tick can retry, and the error propagates (the
/// router reports the job as failed). To use it, wrap the job in
/// `scheduledJobs`: `const OncePerSlotJob(MyJob())`.
class OncePerSlotJob implements ScheduledJob {
  /// Wraps [inner]; [slotsFor] is replaceable for tests.
  const OncePerSlotJob(this.inner, {this.slotsFor = _appwriteSlots});

  /// The job whose slots are guarded.
  final ScheduledJob inner;

  /// Builds the store a run uses.
  final SlotStoreFactory slotsFor;

  @override
  String get name => inner.name;

  @override
  Duration get interval => inner.interval;

  /// [inner]'s scopes plus what claiming a slot needs (rows of `job_slots`).
  @override
  Set<String> get scopes => <String>{
    ...inner.scopes,
    'tables.read',
    'tables.write',
    'collections.read',
    'collections.write',
    'documents.read',
    'documents.write',
  };

  @override
  Future<void> run(ActionContext context, {required int slot}) async {
    final slots = slotsFor(context);
    if (!await slots.claim(name, slot, DateTime.now().toUtc())) {
      context.log?.call('$name: slot $slot already ran, skipped');

      return;
    }
    try {
      await inner.run(context, slot: slot);
    } on Exception {
      await slots.release(name, slot);
      rethrow;
    }
  }
}
