/// The priority band of a job: a worker always claims the highest band that
/// has a claimable job, and within a band the oldest first.
enum JobPriority {
  /// Claimed before everything else.
  high,

  /// The default band.
  normal,

  /// Claimed only when nothing more urgent is waiting.
  low;

  /// The sort rank: lower is claimed first.
  int get rank => index;
}
