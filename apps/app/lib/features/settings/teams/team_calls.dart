import 'package:mvc/mvc.dart';
import 'package:teams/teams.dart';

/// Runs [action] and reports whether it succeeded: a [TeamError] is the
/// expected way a call is refused (not allowed, already invited, offline),
/// so it becomes `false` for the controller to show, never an exception
/// into the view.
Future<bool> attemptTeamCall(Future<void> Function() action) async {
  try {
    await action();
  } on TeamError {
    return false;
  }

  return true;
}

/// The busy/failed bookkeeping every team button shares: a controller mixes
/// this in, says how to show the state ([showCallState]) and how to reload
/// ([reload]), and wraps each button's work in [runTeamCall].
mixin TeamCalls<M extends ViewModel> on ViewController<M> {
  /// Shows whether a call is running and whether the last one failed.
  void showCallState({required bool busy, required bool failed});

  /// Reloads the screen's data after a call worked.
  Future<void> reload();

  /// Marks the screen busy, runs [action] and reloads if it worked,
  /// otherwise marks it failed.
  Future<void> runTeamCall(Future<void> Function() action) async {
    showCallState(busy: true, failed: false);
    if (await attemptTeamCall(action)) {
      await reload();
    } else {
      showCallState(busy: false, failed: true);
    }
  }
}
