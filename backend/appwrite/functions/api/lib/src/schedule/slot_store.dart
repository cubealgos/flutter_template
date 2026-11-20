/// Remembers which (scheduled job, slot) pairs already ran: the one atomic
/// operation `OncePerSlotJob` needs.
abstract interface class SlotStore {
  /// Claims [slot] of [jobName] at [now]. True for the first caller, false
  /// for every later one, however many race: a store holds the pair unique.
  Future<bool> claim(String jobName, int slot, DateTime now);

  /// Gives the claim back so the slot can run again (called when the run
  /// failed). A no-op if there is none.
  Future<void> release(String jobName, int slot);
}
