import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvc/mvc.dart';

part 'home_model.freezed.dart';

/// One still-open onboarding step, as the "Finish your setup" card lists
/// it — just enough to render a row and open the stepper, never the whole
/// `OnboardingStep` (which also carries its body builder — irrelevant
/// here, and not something `HomeController` should need to render).
typedef HomeSetupItem = ({String id, String title});

/// `HomeView`'s view model: the plan's "empty states" landing screen, plus
/// the "Finish your setup" card (spec.md §2.6, superseded by the approved
/// stepper mockups) that links back into onboarding while any step is
/// still open.
@freezed
abstract class HomeModel with _$HomeModel implements ViewModel {
  /// Creates the model.
  const factory HomeModel({
    /// Whether the initial `UserPreferences` read for the setup card is
    /// still in flight. The card never renders while this is `true`.
    @Default(true) bool loadingSetupProgress,

    /// Every onboarding step that is neither completed nor skipped, in
    /// stepper order — an empty list once nothing is left to finish.
    @Default(<HomeSetupItem>[]) List<HomeSetupItem> openSteps,

    /// How many onboarding steps are completed (not skipped) — the card's
    /// "N of total done" line.
    @Default(0) int completedStepCount,

    /// The total number of onboarding steps.
    @Default(0) int totalStepCount,

    /// Whether the user dismissed the card this session (its own "X"
    /// button) — not persisted: a fresh app start (or a step actually
    /// finished) can show it again.
    @Default(false) bool setupCardDismissed,
  }) = _HomeModel;
}
