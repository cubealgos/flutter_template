// File name (`config.dart`) is fixed by the app codegen wiring — see
// CLAUDE.md's "Workspace layout" row — so `AppConfig` can't be renamed to
// match it.
// ignore_for_file: solid_lints/prefer_match_file_name
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:legal_facts/legal_facts.dart';

part 'config.freezed.dart';

/// The app's compile-time configuration: which optional features are on,
/// and the legal-entity facts the Impressum/Datenschutz/AGB screens (see
/// the template plan's default-screen list) are generated from.
///
/// The `legal*` fields default to [LegalFacts] (`core/contracts/legal_facts`) —
/// the one Flutter-free source `apps/website`'s own legal pages read too, so
/// the two can never drift. They stay ordinary `AppConfig` fields (not a direct
/// [LegalFacts] reference) so a clone can still override any one of them per
/// build without touching the shared package.
///
/// Every value here is an **obvious placeholder** — a cloned app must
/// replace every field with its own real facts before shipping. None of it
/// is real personal or company data.
@freezed
abstract class AppConfig with _$AppConfig {
  // solid_lints/number_of_parameters (max 4) is a warning-rule threshold
  // meant for behavioural functions; a configuration object's whole point is
  // one named parameter per independent setting, so grouping these into a
  // sub-object would just move the same count one level down without
  // reducing it.
  // ignore: solid_lints/number_of_parameters
  /// Creates the app's configuration.
  ///
  /// The [Assert] below enforces that [socialLoginGoogle] is never enabled
  /// without [socialLoginApple]: Apple App Store guideline 4.8 requires
  /// offering Sign in with Apple whenever another social login is offered.
  /// freezed compiles this into a plain `assert(...)` in the generated
  /// `_AppConfig` constructor (see `config.freezed.dart`), so it is checked
  /// on every construction in debug/test builds, same as a hand-written
  /// constructor assert.
  @Assert(
    'socialLoginApple || !socialLoginGoogle',
    'Enabling Google social login requires Apple social login too '
        '(App Store guideline 4.8).',
  )
  const factory AppConfig({
    /// Shows the consent sheet (Accept/Reject, no pre-ticking) on first
    /// launch — see §25 TDDDG / Planet49 / LG München I.
    @Default(false) bool consentSheet,

    /// Offers a passkey option on the sign-in screen.
    @Default(false) bool passkeys,

    /// Offers "Sign in with Apple" on the sign-in screen.
    @Default(false) bool socialLoginApple,

    /// Offers "Sign in with Google" on the sign-in screen. Requires
    /// [socialLoginApple] — see this factory's `@Assert`.
    @Default(false) bool socialLoginGoogle,

    /// Shows the subscription screen (web billing with a merchant of record;
    /// a mobile clone selling through the stores replaces it).
    @Default(false) bool paywall,

    /// Shows the Barrierefreiheit (accessibility statement) legal page.
    @Default(false) bool accessibilityStatement,

    /// The legal entity's registered company name, e.g. for the Impressum.
    @Default(LegalFacts.companyName) String legalCompanyName,

    /// The legal entity's registered address.
    @Default(LegalFacts.address) String legalAddress,

    /// The commercial register entry (court and register number).
    @Default(LegalFacts.register) String legalRegister,

    /// The legal entity's VAT identification number.
    @Default(LegalFacts.vatId) String legalVatId,

    /// The contact email shown on legal pages.
    @Default(LegalFacts.contactEmail) String legalContactEmail,

    /// The natural person responsible for content per § 18 (2) MStV.
    @Default(LegalFacts.responsiblePerson) String legalResponsiblePerson,

    /// The supervisory authority shown on the Datenschutz page.
    @Default(LegalFacts.supervisoryAuthority) String legalSupervisoryAuthority,

    /// The running app's own version, compared against the backend's
    /// minimum supported version at bootstrap (`VersionPolicy.check`) —
    /// sourced from the `--dart-define=APP_VERSION=…` build argument in
    /// `ServiceModule.appConfig` (see `apps/app/README.md`), not hand-set
    /// here.
    @Default('1.0.0') String appVersion,

    /// Shows the sign-in screen's "continue as reviewer" shortcut for App
    /// Store/Play Store review (Apple guideline 2.1) — see
    /// `SignInController.submitReviewCode`. Tapping it asks for a shared
    /// review code (never an email or password: this template has no
    /// password sign-in at all — see `AuthService.signInWithReviewCode`'s
    /// dartdoc), which the reviewer types from the store's own review
    /// notes. `false` (the default) hides the shortcut entirely — a
    /// production build with `REVIEW_DEMO_ENABLED` unset ships no review
    /// code UI at all. Sourced from `--dart-define=REVIEW_DEMO_ENABLED=…`,
    /// never hard-coded — see `apps/app/README.md`'s "App Review demo
    /// access" section for the full design.
    @Default(false) bool reviewDemoEnabled,
  }) = _AppConfig;
}
