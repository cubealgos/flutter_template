/// The `UserPreferences` keys this app's screens read and write, gathered
/// in one place so `ConsentController`/`PrivacySettingsController`,
/// `OnboardingController` and `HomeController` (the controllers that touch
/// `UserPreferences`) can't drift into using different literal strings for
/// the same logical value.
library;

/// Whether the user accepted analytics consent — a `bool`, set once by
/// `ConsentController` and changeable again from Settings → Privacy. Absent
/// entirely means "no choice made yet", distinct from either `true` or
/// `false`.
const String consentAcceptedPreferenceKey = 'consentAccepted';

/// Whether the onboarding stepper has been walked through to the end at
/// least once — a `bool`, set by `OnboardingController` the first time it
/// reaches Home (whether every individual step was completed or some were
/// skipped along the way). Read by `resolvePostAuthLocation` to decide
/// whether sign-in/bootstrap should route to onboarding at all — coarser
/// than, and independent of, [onboardingStepStatusPreferenceKey], which
/// tracks each step's own status for the "Finish your setup" card.
const String onboardingCompletedPreferenceKey = 'onboardingCompleted';

/// Per-step onboarding progress — a `Map<String, String>` keyed by
/// `OnboardingStep.id`, valued with an `OnboardingStepStatus.name`
/// ('completed' or 'skipped'). A step with no entry has neither been
/// completed nor skipped yet. Set by `OnboardingController`, read by both
/// it (to resume at the first open step) and `HomeController` (to drive
/// the "Finish your setup" card).
const String onboardingStepStatusPreferenceKey = 'onboardingStepStatus';

/// Per-step onboarding answers — a `Map<String, dynamic>` keyed by
/// `OnboardingStep.id`, valued with whatever that step's own body widget
/// stores (e.g. the profile step's display name). Set and read by
/// `OnboardingController` only; `HomeController` never reads answers, only
/// [onboardingStepStatusPreferenceKey].
const String onboardingAnswersPreferenceKey = 'onboardingAnswers';

/// Whether `HomeController` has already shown its push-notification
/// `PermissionPrePromptView` once — a `bool`, so it's shown in context on
/// first arrival at Home and never nags again every time the screen
/// remounts.
const String pushPermissionPromptShownPreferenceKey =
    'pushPermissionPromptShown';

/// The ID of the team the user is currently working in — a `String`, set by
/// `ActiveTeamService` when they switch teams in Settings → Teams. Absent
/// means "no team chosen yet". Kept per user (it is an account preference),
/// and checked against the user's real teams before use, so a stale ID (a
/// team they were removed from) is ignored, never trusted.
const String activeTeamIdPreferenceKey = 'activeTeamId';
