import 'package:app/app/preference_keys.dart';
import 'package:data/data.dart';
import 'package:flutter/widgets.dart';

/// One step in the per-app onboarding stepper, supplied by
/// [OnboardingStepRegistry] — `OnboardingController`/`OnboardingView`
/// themselves never hard-code a step list, so a clone adds, removes or
/// reorders steps by registering its own [OnboardingStepRegistry]
/// (`ServiceModule.onboardingStepRegistry`), without touching either of
/// those two files.
class OnboardingStep {
  /// Creates a step definition.
  const OnboardingStep({
    required this.id,
    required this.title,
    required this.builder,
    this.onFinished,
    this.defaultAnswer,
    this.skip = OnboardingSkipAffordance.none,
  });

  /// A stable identifier, persisted via `UserPreferences` — must be unique
  /// within [OnboardingStepRegistry.steps]'s list. Never shown to the user.
  final String id;

  /// This step's screen title (rendered `h1`), e.g. "Profile".
  final String title;

  /// Renders this step's body from its own [OnboardingStepScope] — the
  /// step body stays as dumb as any other MVC view: it only reads its own
  /// persisted answer and reports a new one, never advances, skips, or
  /// navigates itself (the generic stepper shell owns that).
  final OnboardingStepBuilder builder;

  /// Whether — and how — this step offers a way to move on without
  /// completing it.
  final OnboardingSkipAffordance skip;

  /// Recorded as this step's answer the first time it becomes current
  /// with none persisted, so a pre-selected default counts as saved.
  /// `null` (the default) records nothing.
  final Object? defaultAnswer;

  /// Runs once, after this step is completed or skipped and its status is
  /// persisted, before the stepper advances. `null` (the default) runs no
  /// side effect. Used by the template's own Notifications step to also
  /// mark the push permission pre-prompt as shown, so `HomeController`
  /// doesn't show it again for a value already framed in the stepper.
  final Future<void> Function(UserPreferences preferences)? onFinished;
}

/// Builds an [OnboardingStep]'s body content from its [OnboardingStepScope].
typedef OnboardingStepBuilder =
    Widget Function(BuildContext context, OnboardingStepScope scope);

/// What an [OnboardingStep]'s body widget is given: its own persisted
/// answer (or `null`) and a way to change it.
///
/// Deliberately narrower than the whole `OnboardingController` — a step
/// body only ever reads or writes its own answer; it never advances, skips
/// or navigates, so it has no need (and no way) to reach anything else the
/// controller can do.
class OnboardingStepScope {
  /// Creates a step's scope.
  const OnboardingStepScope({required this.answer, required this.onChanged});

  /// This step's currently persisted answer, or `null` if none yet.
  final dynamic answer;

  /// Reports a new answer for this step, to be persisted immediately.
  final ValueChanged<dynamic> onChanged;
}

/// Where — if at all — an [OnboardingStep] offers a skip affordance,
/// matching the three shapes the approved mockups use.
enum OnboardingSkipAffordance {
  /// No skip control: the step must be completed via its primary button
  /// (the Profile step's mockup).
  none,

  /// A "Skip for now" text link in the top bar, alongside an ordinary
  /// Back/Next bottom button pair (the Preferences step's mockup).
  topLink,

  /// The bottom bar's secondary button itself skips ("Not now") instead of
  /// going back a step (the Notifications step's mockup).
  bottomButton,
}

/// Whether an [OnboardingStep] has been completed or skipped — persisted
/// per step via [onboardingStepStatusPreferenceKey] (see
/// `preference_keys.dart`).
enum OnboardingStepStatus {
  /// The step was finished through its primary action (Next/Continue).
  completed,

  /// The step was skipped (a "Skip for now" link or a "Not now" button).
  skipped,
}

/// Decodes [raw] — the value stored under
/// [onboardingStepStatusPreferenceKey], exactly as `UserPreferences.getAll`
/// returns it — into a typed status map.
///
/// Shared by `OnboardingController` (to resume at the first open step) and
/// `HomeController` (to drive the "Finish your setup" card), so the two
/// can't drift on how a stored status string is parsed.
Map<String, OnboardingStepStatus> decodeOnboardingStepStatus(dynamic raw) {
  final map = (raw as Map<String, dynamic>?) ?? const <String, dynamic>{};

  return map.map(
    (key, rawStatus) =>
        MapEntry(key, OnboardingStepStatus.values.byName(rawStatus as String)),
  );
}

/// The per-app extensibility point for the onboarding stepper: supplies the
/// ordered [OnboardingStep] list `OnboardingController` walks through.
///
/// A clone replaces `ServiceModule.onboardingStepRegistry`'s factory with
/// one returning its own [OnboardingStepRegistry] implementation (its own
/// steps, in its own order) — `OnboardingController` and `OnboardingView`
/// stay exactly as the template ships them.
abstract class OnboardingStepRegistry {
  /// Returns the ordered steps the stepper walks through, first to last.
  List<OnboardingStep> steps();
}
