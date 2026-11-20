/// Compares [a] and [b] for equality in time proportional to
/// [String.length], not to the position of the first differing character —
/// an ordinary `a == b` (or `String.compareTo`) short-circuits on the
/// first mismatch, which leaks (via response-time measurement) how many
/// leading characters an attacker's guess got right. Used to check the
/// submitted review code against the configured one; the primary defense
/// against brute-forcing that code either way is Appwrite's own execution
/// rate limiting (see `handleReviewDemoSignInRequest`'s dartdoc) — this is
/// defense in depth, not a substitute for it.
///
/// Always compares [b].length characters regardless of where (or whether)
/// a mismatch occurs, so the loop itself takes the same number of
/// iterations for any two strings of matching length; a length mismatch
/// alone is already a public fact (whoever chooses the review code's
/// length also deploys the Function) so returning early for that case
/// leaks nothing new.
bool constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;

  var mismatch = 0;
  for (var i = 0; i < b.length; i++) {
    mismatch |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }

  return mismatch == 0;
}
