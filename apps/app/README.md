# app

The flutter_template default app. See the root `CLAUDE.md` for the workspace's melos
scripts, branch/issue workflow and lint rules.

## `--dart-define`s

The app's backend wiring is entirely compile-time, via `--dart-define`s read in
`lib/app/backend_module.dart` and `lib/app/service_module.dart` — never hand-edited
per environment.

| define | default | meaning |
| --- | --- | --- |
| `BACKEND` | `fake` | `fake` wires every backend-agnostic service (`AuthService`, `DocumentRepository`, `UserPreferences`, `VersionPolicy`, `TeamService`) to its in-memory fake — no network, no real Appwrite instance needed. `appwrite` wires the real adapters from `backend/appwrite/adapters`. **Every `flutter test` run, and a plain `flutter run`/`flutter build` with no defines, uses `fake`** — a developer opts into the real backend explicitly. |
| `APPWRITE_ENDPOINT` | *(empty)* | The Appwrite project's API endpoint, e.g. `https://fra.cloud.appwrite.io/v1` for an Appwrite Cloud project in Frankfurt (see below) or a self-hosted instance's `https://<host>/v1`. Only read when `BACKEND=appwrite`. |
| `APPWRITE_PROJECT_ID` | *(empty)* | The Appwrite project ID. Only read when `BACKEND=appwrite`. |
| `APP_VERSION` | *(empty, `AppConfig` falls back to its own placeholder)* | The running app's own version string (plain dotted integers, e.g. `1.2.3`), compared against the backend's minimum supported version at bootstrap (`VersionPolicy.check`). Set this to the real release version at build time — it is not read from `pubspec.yaml`'s `version:` automatically. |
| `REVIEW_DEMO_ENABLED` | `false` | Shows the sign-in screen's App Review demo shortcut (Apple guideline 2.1) — see "App Review demo access" below. A build with this unset ships no reviewer shortcut and no review-code UI at all. |

### Dev against an Appwrite Cloud project

Set up the project first (`backend/appwrite/README.md`), then:

```
fvm flutter run \
  --dart-define=BACKEND=appwrite \
  --dart-define=APPWRITE_ENDPOINT=https://fra.cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=<from backend/appwrite/tool/.env.local>
```

On web, the project needs a web platform for the origin the app is served from
(`localhost` for local dev) — see `backend/appwrite/README.md`.

On web, the first load before sign-in prints one browser-level console line,
`Failed to load resource ... 401` for `GET /v1/account`. It is expected and
harmless: `AppwriteAuthService.restoreSession` asks the backend whether a session
exists, and "none" is a `401`, which the app treats as "signed out" and logs
nothing. The browser logs every failed fetch itself, so app code cannot hide the
line. Skipping the request instead is unsafe: web OAuth (`createOAuth2Session`)
leaves the session in an API-domain cookie with no stored `cookieFallback`, so
the app cannot know client-side that no session exists. Removing the line would
need Appwrite's token-based web OAuth flow.

### App Review demo access

Apple guideline 2.1 requires reviewers be able to sign in without any interactive
step this template's email-OTP flow can't satisfy for someone who can't receive
the code (a reviewer has no access to the demo account's inbox) — and, per the
same guideline, that sign-in should exercise the app's real functionality, not a
build that never touches the real backend at all (the original approach:
review builds ran entirely against `BACKEND=fake`, which avoided the OTP problem
but meant the reviewer never saw a real Appwrite-backed account — a rejection
risk of its own).

**Design: a shared review code, exchanged for a session on one allow-listed
account by a dedicated Function, shown only behind a build-time switch.** A
first version of this design used an email+password session
(`Account.createEmailPasswordSession`) for the one allow-listed demo account.
**That design was wrong and was replaced before shipping** — reviewed and
found to be a real account-takeover hole, live-verified: `email-password` is
one of Appwrite's auth methods, enabled project-wide by default, and leaving
it enabled at all (even scoped to "only the demo account has a password") means
*any* client can call the public `Account.create(userId, email, password)`
endpoint for an arbitrary, unverified email. Combined with the live-verified
finding that `createEmailToken` looks a user up **by email** and
silently reuses whatever account already owns it (see
`AppwriteAuthService`'s "Email-code existence finding" dartdoc), that's a real
takeover: an attacker pre-creates `victim@x` with a password of their choosing,
the victim later signs up for real through this template's own email-OTP flow,
and lands in the *attacker's* pre-created account — the attacker, still holding
the password, can sign in as the victim at any time. This has nothing to do
with which account the demo shortcut targets; it's a hole in leaving the
`email-password` method enabled at all.

The shipped design instead:

- **Disables every auth method this template doesn't use, project-wide.**
  `backend/appwrite/tool/lib/src/provisioner.dart`'s `Provisioner` disables `email-password`,
  `magic-url`, `invites`, `jwt`, `phone` and `anonymous` on every provisioning
  run (the dev project *and* any real deployed one — see `backend/appwrite/README.md`) —
  live-verified: after provisioning, both `Account.create` with a password
  and `Account.createEmailPasswordSession` are refused outright (`501
  user_auth_method_unsupported`), while `email-otp` (this template's real,
  and only, sign-in flow) keeps working. With `email-password` disabled
  project-wide, there is no password session left to build the demo path on
  at all.
- **A dedicated action (`review_demo_sign_in`) of the `api` Appwrite Function exchanges a shared
  code for a session token on one allow-listed account fixed server-side.**
  `backend/appwrite/functions/api`'s `review_demo_sign_in` action (the Function's execute
  permission is `any` and the action needs no signed-in caller — it must
  be callable with no session, exactly like the reviewer it exists for has
  none) compares the submitted code (constant-time comparison, plus a small
  fixed delay on a mismatch — defense in depth; the actual anti-brute-force
  defense is Appwrite's own execution rate limiting, not reimplemented here)
  against its own `REVIEW_DEMO_CODE` function variable and, on a match, calls
  the server `Users.createToken` for its own `REVIEW_DEMO_USER_ID` function
  variable — **never the request** — and returns `{userId, secret}`. The app
  then calls the same `Account.createSession(userId, secret)` its own
  email-OTP flow already ends with
  (`AppwriteAuthService.signInWithReviewCode`). A wrong code gets a generic
  401, never revealing anything about which account exists.
- **The app-side path takes only a code, never an email or password.** The
  sign-in screen's "continue as reviewer" shortcut only appears when
  `REVIEW_DEMO_ENABLED` is set at build time, and `AuthService
  .signInWithReviewCode` takes just the code — there is no email or password
  field on this path anywhere, so it can't be pointed at an arbitrary account
  even by someone reading the shipped binary's strings.
- **A production build with `REVIEW_DEMO_ENABLED` unset ships no review-code
  UI at all.** `AppConfig.reviewDemoEnabled` is `false` by default,
  `showReviewerButton` hides the shortcut entirely, and `SignInStep
  .reviewCode` is simply unreachable — not merely hidden behind a runtime flag.

**The credential is never in source.** `REVIEW_DEMO_ENABLED` is a `--dart-define`
boolean (not a secret). The review code never is: it is generated by
`backend/appwrite/tool/bin/seed_review_demo_account.dart`, written once to the shared,
gitignored `backend/appwrite/tool/.env.local`, and from there goes only into the App Store
Connect / Play Console reviewer-notes field a human copies it into — never into
a dart-define, never compiled into the binary. The reviewer types it by hand
into the same code field a real user never sees, the same way an earlier OTP
build had the reviewer type `123456` by hand.

**Seeding the account** (idempotent — rerun any time, e.g. after every deploy; a
second run against an already-configured account is a no-op):

```
cd backend/appwrite/tool
dart run bin/deploy.dart api   # once, or after any change to it
dart run bin/seed_review_demo_account.dart reviewer@example.com
```

See `backend/appwrite/README.md`'s own copy of this section for what it writes and where.

**Building a review release**, against the real backend like any other release
build (see "Dev against an Appwrite Cloud project" above for the
`--dart-define`s; a production project uses its own real endpoint/project ID):

```
fvm flutter build ios \
  --dart-define=BACKEND=appwrite \
  --dart-define=APPWRITE_ENDPOINT=https://<host>/v1 \
  --dart-define=APPWRITE_PROJECT_ID=<project-id> \
  --dart-define=REVIEW_DEMO_ENABLED=true
```

**What to put in the review notes** (App Store Connect's "App Review Information"
→ Notes, and Play Console's equivalent reviewer-access notes): the review code
`backend/appwrite/tool/.env.local`'s `REVIEW_DEMO_CODE` holds after seeding — copied by hand
from that file, never pasted anywhere this repo commits — plus a one-line
instruction that the app's sign-in screen has a "continue as reviewer" shortcut
that asks for it. Rotating the demo account (a different underlying account) is just rerunning
`bin/seed_review_demo_account.dart` with the new email; a new code for the same
account is `bin/seed_review_demo_account.dart --rotate <email>` (also the repair
for a blank secret `REVIEW_DEMO_CODE` variable on Cloud, which looks configured
because the API hides secret values). Either way the old code stops working, so
update the store's notes to match;
nothing in the shipped app needs to change.

## Feature structure

Every screen is an MVC triad (`*_view.dart`, `*_controller.dart`, `*_model.dart`) under
`lib/features/`. The layout follows these rules.

**Scaffold a new one with `fvm dart run tooling:new_feature <path>`** (e.g. `settings/notifications`; the
parent folder must already exist). It writes the triad, `layouts/<f>_mobile_layout.dart`, a view test and a
layout test under `test/features/<path>/`, and wires a `TypedGoRoute` (kebab-cased path) plus its route class
into `lib/app/router.dart` — or prints the snippet to add if `router.dart` has an unexpected shape. Everything
is named after the last path segment (`NotificationsView`, `NotificationsRoute`). It refuses an existing path,
the reserved `widgets`/`layouts`/`steps` and any segment that is not snake_case. Run `fvm dart run melos run
gen` afterwards (regenerates `router.g.dart`); the screen title is placeholder copy until you move it into
`lib/i18n/`.

- **Features nest by route.** A screen whose route sits under another screen's route is a
  sub-feature folder inside it: `legal/` (the legal hub) holds `document/` and `licences/`,
  `settings/` (the settings hub) holds `account/`, `privacy/` and `paywall/`. `bootstrap`,
  `sign_in`, `consent`, `onboarding`, `home` and `permission_pre_prompt` stay top level.
  Folders move, names don't: `settings/account/account_settings_view.dart`. Adding a screen
  under an existing route means a new sub-feature folder there, not a top-level one.
- **A feature root holds** the triad, feature-local types (enums, small value types), the
  reserved folders `widgets/`, `layouts/` and `steps/`, and its sub-feature folders. Those
  three names are reserved and never a sub-feature.
- **Helper widgets live in `widgets/`, one public widget per file** (file name = class name in
  snake_case, dartdoc on every public member). A view file declares only its view; the
  `avoid_extra_widgets_in_view_files` lint enforces it. Widgets take data and plain callbacks
  (`VoidCallback`, `ValueChanged<T>`), never the controller, and files under `widgets/` or
  `layouts/` get the same import and navigation restrictions as a view
  (`core/architecture/mvc_lints`).
- **One view, up to three layouts.** `<f>_view.dart` stays the feature's only `ViewWidget`: it
  owns the controller and builds a `ResponsiveLayout` (from `core/architecture/mvc`), so
  crossing a breakpoint never recreates the controller or loses its state. The layouts live in
  `layouts/`: `<f>_mobile_layout.dart` is required, `<f>_tablet_layout.dart` and
  `<f>_desktop_layout.dart` exist only where the screen really differs (names keep the feature
  prefix, classes are `<Feature>MobileLayout` etc.). A layout is a dumb widget that renders a
  whole screen from the model and the controller's callbacks, never the controller itself, and
  gets the same lints as `widgets/`. **Fallback:** desktop, else tablet, else mobile; tablet,
  else mobile. So a feature with only a mobile layout looks the same on every viewport, and
  today home, onboarding and sign-in add a desktop layout. Breakpoints are the design system's
  (`Breakpoint`: mobile below 768, tablet 768-1023, desktop from 1024), measured from the
  **viewport** (`MediaQuery`), never from parent constraints: a screen body sits inside a
  width-capped content wrapper, where constraints would never report a wide window. A layout
  may still read its own constraints for *height* (centering a group), but never for the
  breakpoint, and no view file contains a `LayoutBuilder` or `Breakpoint`. Layouts whose
  variants share content share it through a `widgets/` widget (e.g. `HomeScreenFrame`,
  `SignInForm`).
- **Placement: as close as possible to everything that uses it.** The feature's own
  `widgets/`; the parent feature's `widgets/` when sibling sub-features use it; `lib/shared/
  widgets/` when several top-level features do (e.g. `LegalLinksRow`, used by sign-in and the
  paywall). Brand-neutral widgets reusable in any app belong in `core/design/ui` instead.
- **`test/features/` mirrors `lib/features/`.**
- **i18n namespaces mirror the feature tree.** In `lib/i18n/*.i18n.json` a top-level feature is a
  top-level key and a sub-feature nests under its parent's key: `settings.account`,
  `settings.privacy`, `settings.paywall`, `legal.document`, `legal.licences`. A string lives in
  the namespace of the deepest feature whose code uses it (strings shared by a hub and a
  sub-feature stay in the hub), and inside a sub-feature namespace keys drop the feature prefix
  (`legal.licences.copyButton`). A parent's label for navigating to a sub-feature is
  `<target>Link` (`settings.privacyLink`, `legal.licencesLink`), matching `common.legalLink`;
  the sub-feature's own screen title is still its own `title` key (`legal.licences.title`), even
  when the text is the same.
  `appTitle` and `common` (strings several features share) stay top level. `de` has exactly
  `en`'s key structure.

## Teams and team-scoped rows

A B2B app is an organisation of several people sharing data. The template ships the tenancy plumbing so a clone
never hand-rolls it in an adapter, where a mistake leaks one customer's data to another. **A single-user app can
ignore all of this** (nothing registers a team unless the user opens Settings → Teams).

**User-scoped or team-scoped rows: ask "whose is this row?"**

- **User-scoped** (`UserScope`, the default of `DocumentRepository.create`/`query`): one person's own data. A
  profile, personal settings, drafts, anything that should vanish from the app when that person deletes their
  account (declare it in `TableOwnership` so `delete_account` removes it). Appwrite permission: `Role.user(id)`.
- **Team-scoped** (`TeamScope(teamId)`): data an organisation's members share. Every member sees the same rows, a
  removed member loses access at once, and the data outlives any one member's account (so it has **no**
  `TableOwnership`). Appwrite permission: `Role.team(teamId)`. Narrow it by role with
  `TeamScope(teamId, readRoles: {'admin'}, writeRoles: {'admin'})` (members read, admins write:
  `readRoles: {'member'}, writeRoles: {'admin'}`). A member holds the roles `TeamRoles.implied` lists (owner =
  owner + admin + member, admin = admin + member), so an admins-only row is also readable by the owner. A creator
  can only scope a row to roles they hold themselves (Appwrite refuses anything else), so a plain member cannot
  mint an admins-only row. An app-defined role (`auditor`) must be added to `TeamEngine.assignableRoles` and doesn't
  imply the owner: name `owner` in the set too if the owner should see it.
- A table holds one kind or the other. A team-scoped table needs a `teamId` column (and an index on it); the
  template's `team_notes` table is the worked example, and `AppwriteDocumentRepository(..., teamColumn:)` renames
  the column. `query(const DataQuery(), TeamScope(id))` lists one team's rows; the default scope lists only the
  caller's own.
- **Test it with the fakes**: `FakeTeamBackend` is the tenancy state, and `FakeDocumentRepository(teams: backend,
  userId: 'ada')` (`.asUser('grace')` for a second user over the same rows) enforces the same visibility as
  Appwrite, so a unit test can prove a member of team A never reads team B's rows.

**Where the rules live.** `core/contracts/teams` (a separate contract so a single-user clone doesn't carry it)
holds `TeamService`, the models and `TeamEngine`, the one implementation of the rules: **exactly one owner**,
ownership transfer, invite/accept/expire/revoke, role changes, removal, leaving, and a per-team history of every
membership event (actor, subject, role, time, email snapshot) that outlives the memberships. `FakeTeamService` and
the real backend run the same `TeamEngine`, so they cannot disagree.

**Why a Function, not the Teams SDK.** Appwrite Teams has no "exactly one owner" rule and no atomic ownership
transfer: a member whose native role is `owner` can add more owners, demote the only one or delete the team straight
from the client SDK, and a client can't be trusted to keep an invariant. So `AppwriteTeamService` calls
the `team_admin` action of `backend/appwrite/functions/api` for every operation, which runs `TeamEngine` with an API key, and nobody is
ever given Appwrite's native `owner` role (the contract's owner holds `tenant_owner`, `admin` and `member`, see
`nativeOwnerRole`), so the Teams SDK refuses even the owner a direct membership change. Memberships still live in
native Appwrite Teams, which is what makes `Role.team(...)` row permissions work; invitations and the history live
in two `serverOnly` tables no client can read or write. Invitations carry no emailed secret: the invitee signs in
with the invited (verified) email and accepts from Settings → Teams; delivering a "you've been invited" email is the
clone's job (Appwrite Messaging, or a Function on `team_invitations` creates).
Limits, stated honestly: Appwrite has no cross-membership transaction, so a transfer records its event, promotes the
new owner and then demotes the old one (never zero owners; the next call repairs an interrupted one), and two
concurrent conflicting calls by the same owner are not serialised.

**Deleting an account.** The `delete_account` action **refuses, server-side, while the caller owns any team**:
deleting would leave the team without its owner. Nothing is deleted; the action answers 409
`owns_teams` with the team names, `AuthService.deleteAccount` throws `AuthOwnsTeamsError`, and the account-deletion
screen (Settings → Account) shows "You own "Acme". Transfer ownership to another member, or delete the team, ...".
An admin or member deletes freely: their memberships go with the user (Appwrite does that), the team keeps its owner,
and the history entries they appear in stay (the history is append-only and outlives membership). The fake mirrors
the refusal (`FakeAuthService.ownedTeamNames`, wired to `FakeTeamBackend` in `backend_module.dart`), so the app tests
prove the screen. A race (the user creates a team in the instant between the check and the deletion) is not
excluded; the next owner-less team would show up as a team with no owner, which is the clone's to repair.

**The history's personal data.** Each history event keeps an **email snapshot** of the people involved, so the
record stays readable after their account is gone. That is an *audit record*: a clone should state its legal basis
in its privacy notice, usually GDPR Art. 6(1)(f) (the legitimate interest in an accountable audit trail of who
joined, left or held which role) or Art. 6(1)(c) where a law requires keeping it. This is guidance, not legal advice:
the clone decides and documents it. Because the basis is a legitimate interest, keep it proportionate: a
**retention hook** replaces an event's email snapshot by the neutral marker `MembershipEvent.formerMember`
("former member") once it is older than a configurable period, and keeps the user IDs, event types, roles and times.
The template sets **no expiry by default**; a clone that needs one typically sets 12 months. See `backend/appwrite/README.md`
"Team tenancy" for how to switch it on.

**The UI.** The template ships a minimal team flow, behind the MVC rules: Settings → Teams
(`lib/features/settings/teams/`: create a team, accept an invitation, switch the active team) and its Members
sub-feature (`teams/members/`: members, invite by email as a member, revoke a pending invitation, leave).
`ActiveTeamService` remembers the active team in `UserPreferences` and the screens ignore a stale ID. Not in the
UI, though in `TeamService` (a clone adds the buttons): removing a member, changing a role, transferring ownership
and reading the history.

## Billing and the paywall

`settings/paywall` is the web subscription screen, behind `AppConfig.paywall` (off by default). It reads the owner's
**entitlement** and starts the checkout; it never talks to the payment provider. `Billing` (`core/contracts/billing`)
is the interface: `AppwriteBilling` calls the `billing` action of the `api` Function, and on the fake backend
(`BACKEND=fake`, the default) `FakeBilling` runs in memory, so a checkout there charges nothing and opens a URL that
leads nowhere (the unit tests play the webhook with `FakeBilling.completeCheckout`). The server design (Paddle as the
merchant of record, the webhook ledger, the grace period, the reconciler) is in `backend/appwrite/README.md`,
"Billing".

- **Owner, team-first.** `BillingOwnerResolver` bills the **active team** while the user still belongs to it, otherwise
  the user. A team subscription is shared by every member; only the team's owner or an admin can start, change or
  manage it (the server decides, from the caller's identity, never from anything the app sends).
- **What the screen does.** It shows the status in words (none, active, trial, payment failed with the date access
  ends, paused, canceled), the units and the renewal date, a "- n +" control for the quantity, and the buttons that fit:
  *Subscribe* (opens the provider's checkout in the browser), *Change units (prorated)* and *Manage billing* (the
  customer portal, which also cancels). After paying, *I have paid, refresh* reloads the entitlement: the webhook may
  land a moment after the buyer returns, and the screen only ever shows what the server computed.
- **The plan.** `defaultBillingPlan` (`lib/app/billing_plans.dart`) is the one plan the template sells; it must be a key
  of the `api` Function's `PADDLE_PLANS`. A clone with several plans replaces it with its own list.
- **The old store-shaped stub is replaced, not kept.** The template releases on the web only, so the screen with Apple
  3.1.2 disclosure slots and no billing code is gone (its `planPlaceholderTitle`/`priceAmount`/`autoRenewNotice`
  strings with it). A **mobile clone that sells through the App Store or Play Store** replaces `PaywallView`'s layout
  with its store SDK and the disclosures those stores require (price, period, auto-renew terms, links to the terms and
  privacy policy; the `LegalLinksRow` stays), and must not link out to a web checkout from inside the iOS app.
- **Gating server work.** An `api` job or a worker gates on `Entitlement.hasAccess`, never on the status alone (see
  "Server-side gating" in `backend/appwrite/README.md`).

## Accessibility on web

Flutter web paints to a canvas, so a screen reader and axe see only the semantics DOM
(`flt-semantics`) Flutter builds beside it. `main()` turns that tree on at start-up
(`SemanticsBinding.ensureSemantics()`, web only); by default it exists only after a user finds and
activates a hidden "Enable accessibility" button. Three automated layers run:

- **Widget tests** — `pumpScreen` (`test/support/screen_harness.dart`) asserts `flutter_test`'s
  `textContrastGuideline`, `labeledTapTargetGuideline`, `androidTapTargetGuideline` and
  `iOSTapTargetGuideline` for every screen in light and dark, so generated feature tests inherit them.
- **axe-core** — `melos run web-smoke` boots the built web app in headless Chromium, injects axe and
  fails on any serious or critical violation in the semantics DOM.
- **CI** — the `web-smoke` workflow runs the second layer on every PR.

What they cannot cover: axe cannot see the contrast of canvas-rendered text (it is not in the DOM),
so contrast is covered only by the widget-test guideline, which measures against the themed
background in a test render. Nor can automation judge reading order, whether a label is meaningful,
focus behaviour in a real browser, or what a screen reader actually announces. Before a release, do
a manual pass with NVDA (Windows) and VoiceOver (macOS and iOS) through the main flows.

## Release boundaries this template does not cover

**Push notifications are pre-prompt only.** `lib/features/permission_pre_prompt/` explains a
system permission (push, App Tracking Transparency, location) before the real platform prompt
appears — that's as far as this template goes. No push-notification *delivery* is wired: no
FCM, no APNs, no Appwrite Messaging. Adding one is per-app work (a clone's own project in the
chosen push provider, the client SDK, and the platform entitlements/manifest entries it needs).

**Release signing is per-clone setup, on both platforms.** `android/app/build.gradle.kts`'s
`release` build type currently signs with the debug key — `flutter create`'s own default, left
unchanged here (see that file's own comment) — so `flutter build apk --release` runs, but is not
something you'd ship. iOS is likewise whatever Xcode's default signing left it as. Configure your
own Android keystore/signing config and your own iOS team/certificates before a real store
release; this template never verifies either.

**Web is the only release platform this template targets** — see the root `CLAUDE.md`'s "Licence
and release boundaries" and `docs/releasing.md`. Nothing here builds or checks `apps/app` for
Android/iOS as part of the release gate.
