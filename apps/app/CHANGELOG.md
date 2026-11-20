# Changelog

All notable changes to `app` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged `app-vX.Y.Z` (see
`docs/releasing.md`).

## [Unreleased]

### Added

- Web billing: the subscription screen (`settings/paywall`) now reads the owner's entitlement and starts the
  checkout, changes the quantity (prorated) and opens the customer portal through `Billing` (`AppwriteBilling`, or
  `FakeBilling` on the fake backend); `BillingOwnerResolver` bills the active team first, else the user. The
  store-shaped stub (plan placeholders, Apple 3.1.2 slots) is replaced; a mobile clone adds its own store paywall.
  en/de strings.

### Fixed

- Deleting an account that owns a team is refused: Settings → Account shows the team names and the
  transfer-or-delete hint (en/de); the fake backend mirrors it. README documents the history's email snapshot
  as an audit record and the retention hook.

### Added

- Teams: Settings → Teams (create a team, accept an invitation, switch the active team) and
  Teams → Members (members, invite, revoke, leave), `ActiveTeamService`, a `TeamService` registration
  (Appwrite or an in-memory fake tenancy backend), en/de strings, README "Teams and team-scoped rows"
  (user-scoped versus team-scoped rows, the design and its limits).

- Web semantics are enabled at start-up (`SemanticsBinding.ensureSemantics()` in `main()`), so the
  `flt-semantics` DOM exists from the first frame for screen readers and axe.
- The `pumpScreen` test harness asserts `textContrastGuideline`, `labeledTapTargetGuideline`,
  `androidTapTargetGuideline` and `iOSTapTargetGuideline` for every screen in light and dark, so
  generated feature tests inherit them; `expectAccessible` runs them standalone.
- README: what automated checks cannot cover on Flutter web, and the manual NVDA/VoiceOver pass.

### Removed

- The `APPWRITE_SELF_SIGNED` define and `buildAppwriteClient`'s self-signed handling; the dev
  backend is an Appwrite Cloud project with a real certificate, so the local stack's `:8443`/`:8080`
  guidance is gone from the README too.

### Changed

- Every `Box(style: BoxStyler().height(spaceN()))`/`.width(spaceN())` spacer in the views now
  reads `AppGap.vN()`/`AppGap.hN()`; same size and axis, no visual change.
- Every feature view is now the only `ViewWidget` of its feature and builds an `mvc`
  `ResponsiveLayout` over `layouts/<f>_mobile_layout.dart` (plus `<f>_desktop_layout.dart` where
  the screen differs on desktop: home, onboarding and sign-in); the layouts are dumb widgets
  taking the model and the controller's callbacks. Breakpoints are measured from the viewport in
  one place (`ResponsiveLayout`), replacing the per-view `LayoutBuilder`/`Breakpoint` checks; the
  looks at each width are unchanged. Home's and onboarding's `HomeBody`/`OnboardingBody` and
  `PhoneHomeLayout`/`DesktopHomeLayout` became the layout files, sharing a `HomeScreenFrame`/
  `OnboardingScreenFrame`; sign-in's form moved to `widgets/sign_in_form.dart` and the licence
  detail sheet to `widgets/licence_detail_sheet.dart`.
- `lib/features/` is nested by route: `legal/` holds `document/` and `licences/`,
  `settings/` holds `account/`, `privacy/` and `paywall/`; file and class names, routes and
  URLs are unchanged. `test/features/` mirrors the new tree.
- The i18n files' namespaces now mirror the feature tree: `account`, `privacy` and `paywall`
  moved under `settings.`, `legal` gained `legal.document` (the document texts and imprint facts)
  and `legal.licences` (`title`, `copyButton`, `empty`); the hubs' navigation labels are now
  `settings.legalLink`/`privacyLink`/`accountLink`/`paywallLink` and `legal.licencesLink`. No
  string value changed.
- Every private helper widget in a view moved into a `widgets/` folder next to it (one public
  widget per file, taking data and callbacks instead of the controller); the sign-in and
  paywall legal link rows are now one shared `LegalLinksRow` in `lib/shared/widgets/`, and
  their link labels moved to `common.legalLink`/`agbLink`/`datenschutzLink` in the i18n files.

### Added

- The flutter_template default app — a clone target, renamed via `fvm dart run
  tooling:rename --name <snake_case> --org <reverse.domain> --display "<Display Name>"`.
- MVC-triad screens under `lib/features/`: bootstrap, sign-in (email OTP, plus an
  App-Review demo sign-in path behind `REVIEW_DEMO_ENABLED`), onboarding, home, a
  permission pre-prompt component (push notifications, App Tracking Transparency,
  location — explains a system permission before the real platform prompt appears; no
  push-notification delivery is wired, see the root CLAUDE.md), a paywall placeholder,
  consent, account settings, privacy settings, a settings hub, and a legal hub with a
  generic legal-document viewer and a third-party licences screen.
- Compile-time backend wiring via `--dart-define`s (`BACKEND=fake|appwrite`,
  `APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID`, `APPWRITE_SELF_SIGNED`, `APP_VERSION`,
  `REVIEW_DEMO_ENABLED`) read in `lib/app/backend_module.dart`/`service_module.dart`;
  `fake` (no network, no real backend) is the default for every test run and a plain
  `flutter run`/`flutter build`.
- `get_it`-based DI (`lib/app/di.dart`), a `go_router` route table (`lib/app/router.dart`),
  and `AppConfig`, whose `legal*` fields default from `package:legal_facts`.
- i18n scaffolding under `lib/i18n/` (slang-generated).
- Android and iOS platform projects from `flutter create`, unmodified beyond the
  application ID; release signing on both platforms is per-clone setup, not verified by
  this template (see the root CLAUDE.md and `android/app/build.gradle.kts`).

### Fixed

- `README.md` no longer ends with `flutter create`'s generic "Getting Started" boilerplate
  — the file already documents this app's own `--dart-define`s and release
  boundaries in full.
