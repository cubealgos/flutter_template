/// Waits for pending async work started from a `ViewController.init()` to
/// finish — e.g. a chain of several sequential `await`s (a fake service
/// call, then another fake service call, then a `NavigationService` call)
/// started by a constructor but not itself awaited by the test.
///
/// A single `await Future<void>.delayed(Duration.zero)` is not reliably
/// enough here: it only guarantees the *current* microtask queue drains
/// before its own zero-duration timer fires, but each `await` in a chain
/// of `async` methods (`_run` awaiting `VersionPolicy.check`, then
/// `AuthService.restoreSession`, then `UserPreferences.getAll`, …)
/// schedules its continuation as a *new* microtask only once the previous
/// one resolves — found by hand while writing this template's controller
/// tests, where a single delayed-zero wait intermittently observed a
/// controller still in its initial "checking"/"loading" state. Looping a
/// handful of real (non-zero) delays gives every link in such a chain its
/// own event-loop turn instead.
Future<void> settle({int turns = 10}) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}
