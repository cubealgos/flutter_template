# flutter_template app — UI design spec

Design input for the mockups, approved on 2026-09-26 and written before implementation. The
template's default screens and their flow rules were settled before this spec (no carousel,
email-first OTP, equal-weight consent, legal ≤2 taps, delete without a ticket); this document
takes them as given and answers how the screens should **look**.

Visual direction: adopt the type system (Host Grotesk + IBM Plex Mono) and dark palette of a
reference site, an Astro marketing website that is not part of this repository; derive a light
theme from it; and use **square corners**. The reference site's clip-path "chamfer" (cut-corner)
system is explicitly **not** ported; plain `border-radius: 0` throughout, true circles
(avatars/status dots) excepted. Throughout this document, "the website" means that reference
site, not `apps/website`.

Code reviewed for this spec: `apps/app/lib/features/*` (13 screens/dialogs) and
`core/design/ui/lib/src/{components,theme}/*` + `core/design/ui/tokens/*.json`. Wherever this
document says "current", "currently" or "today" (§0, §3 and the per-screen notes), it describes
the code as it stood when the spec was written; the file:line citations point at that state, not
at the released code.

---

## 0. Headline finding

The current component package (`core/design/ui`) is **architecturally sound** — headless
naked_ui + mix, token-driven, 44px hit targets everywhere, disabled/loading/hover/focus states
handled per component. The app's unfinished look is not a component-engineering problem. It has
two root causes, both fixable without touching the MVC/component architecture:

1. **The token values themselves are wrong for a consumer app.** `core/design/ui/tokens/*.json`
   is a verbatim copy of a *diagram/architecture-drawing* design system (a separate
   diagramming design system's tokens — series-1..5 chart colors, tier-security/observability/product/working/archive domain
   colors, ink-band/ink-deep "parametric architecture" colors, Instrument Serif + Geist + Geist
   Mono fonts, 4/6/8px radii). None of that belongs in a product UI, and it directly contradicts
   the Host Grotesk/IBM Plex Mono/square-corner direction. This is a token-file replacement,
   not a redesign of the components that consume them.
2. **Every screen's headings, body copy, and hints are raw, unstyled `Text()` widgets.** Only
   `AppButton`, `AppTextField`, `AppListTile`, `AppCheckbox` route through the design system;
   every `Text(t.foo.title)` in every one of the 13 screens (see §3, "what's wrong" per screen)
   renders in Flutter's un-themed default style — no font family, no explicit size, no color, no
   hierarchy between an H1 and a caption. This is why the app looks like a wireframe: there is
   currently no typographic system applied to a single screen's actual page content, only to its
   buttons and form fields.

Fixing §0.1 (token file) and adding a small set of typography helper widgets used consistently
(§1.2) resolves most of the visual problem before any per-screen layout work.

---

## 1. Global rules

### 1.1 Layout grid, breakpoints, max widths

| Rule | Value | Evidence | Strength |
|---|---|---|---|
| Reference mobile width | 390px (iPhone 14/15/16 logical width) | Industry-standard reference device | n/a (convention) |
| Breakpoints | mobile <768px · tablet 768–1023px · desktop ≥1024px | Verbatim reuse of the website's own breakpoints (`Hero.astro:16,23`: `@media (min-width: 768px)` / `@media (min-width: 1024px)`) | Internal consistency, not external research |
| Base spacing unit | 4px | `--space-*` scale, identical in the website tokens and the current (wrong-value-but-right-structure) app tokens | Convention, both sources agree |
| Spacing scale (px) | 4, 8, 12, 16, 24, 32, 48, 64, 96 | Direct port of the website's `--space-1..8` (dropped `--space-10`/`-11`, 128/192px — no app screen needs page-level gaps that large) | Convention |
| Screen edge padding, mobile | 16px (dense screens: settings/legal lists) or 24px (auth/consent/onboarding, which read as a single "card" of content) | Matches both the website's `--space-4`/`--space-5` and the current app code's own choice (`EdgeInsets.all(16)` on lists, `EdgeInsets.all(24)` on sign-in/consent) — this part of the current app already got it right | Convention |
| Auth/dialog screen max width, desktop | 440px, centered | Convergent secondary sources (no single controlled study found): login-form max-widths cluster 380–450px across surveyed implementations | **Weak** — practice convention, not a controlled study. Open to revision if a stronger source turns up. |
| List/settings screen max width, desktop | 640px, centered, list rows fill the width | No controlled study found; avoids settings rows stretching edge-to-edge at 1280px, which reads as broken, not just "wide" | **Weak** — practice convention |
| Long-text (legal) reading measure | 65ch target, 45–75ch acceptable range | Bringhurst's classic 45–75-character-per-line typographic guideline, corroborated by Baymard's finding that ecommerce copy wider than 80cpl is skipped 41% more than 60–70cpl copy | **Strong** — classic typographic research + independent corroborating data. [Baymard: Readability — The Optimal Line Length](https://baymard.com/blog/line-length-readability) |
| Home/dashboard content max width, desktop | 960px, centered (content), full-bleed background | No controlled study; scaled down from the website's 1280px container since the app has much less horizontal content than a marketing page | **Weak** — practice convention |
| Minimum touch target | 44×44px (44dp) | WCAG 2.5.5 (Level AAA) / 2.5.8 (Level AA, 24×24 CSS px minimum, 44px recommended) — already enforced in every current `core/design/ui` component via `_minHitTarget = 44` | **Strong** — W3C normative requirement, and already correctly implemented; keep as-is |

### 1.2 Typography

Two font families only, by design, both available as full-axis self-hostable packages and used
that way on the website (`@fontsource-variable/host-grotesk`,
`@fontsource/ibm-plex-mono/400.css`) — same fonts, same distribution mechanism: self-hosted,
never loaded from the Google Fonts CDN, a GDPR precaution the website's own `fonts.css` states.

- **Host Grotesk** — headings, body, **and eyebrow/label text** (600 weight, uppercase, tracked —
  see the note below the type-scale table). Variable weight 300–800; use 700 for
  H1/H2, 600 for H3/button/eyebrow/label text, 400 for body.
- **IBM Plex Mono** — data/code display only (OTP digits, exported JSON, licence package
  identifiers), never body prose, never eyebrow labels. Weight 400 only (the website imports no
  other weight).

Type scale (adapted from the website's `--text-*` scale, trimmed to what a phone/tablet app
actually needs — the website's 56/72px hero sizes have no use case here):

| Token | Size | Line-height | Weight/family | Use |
|---|---|---|---|---|
| `display` | 32px | 1.1 | Host Grotesk 700 | Paywall price only; the one place a number should dominate |
| `h1` | 24px | 1.2 | Host Grotesk 700 | Screen title (one per screen, top of content) |
| `h2` | 20px | 1.3 | Host Grotesk 700 | Section heading within a screen (e.g. "Linked accounts", "Export your data") |
| `h3` | 16px | 1.3 | Host Grotesk 600 | Card/group title, dialog title |
| `body` | 16px | 1.6 | Host Grotesk 400 | Default paragraph/list text. **16px is the floor, not a stylistic choice** |
| `body-sm` | 14px | 1.5 | Host Grotesk 400 | Secondary text, list subtitles, helper text |
| `caption` | 12px | 1.5 | Host Grotesk 400, `color-muted` | Fine print, legal footnotes, timestamps |
| `eyebrow` | 14px | 1.4 | Host Grotesk **600, uppercase, `letter-spacing: 0.04em`** — **not** IBM Plex Mono | Section labels ("CONSENT", "STEP 2 OF 2"), status tags |
| `mono-data` | 16px | 1.4 | IBM Plex Mono 400 | OTP code entry, exported JSON block, package identifiers in Licences |
| `button` | 16px | 1 | Host Grotesk 600 | Button label (already matches the website's `.hero__cta`: `font-size: var(--text-base)`, `font-weight: 600`) |

**Why the eyebrow is not monospace.** On the website, `Hero.astro`'s `.hero__eyebrow` rule
(`font-size: var(--text-sm); font-weight: 600; text-transform: uppercase; letter-spacing:
0.04em;`) carries **no `font-family` override at all**, so it inherits the page's body font —
Host Grotesk, not mono. The only component in that source that uses `font-family:
var(--font-mono)` is `StackPills.astro`'s tag list (a tech-stack tag list, i.e. genuinely
tabular/data content), not eyebrows. Hence eyebrow = Host Grotesk 600 uppercase, tracked 0.04em
as in the source. IBM Plex Mono's role is data/code/identifiers (OTP digits, JSON, package
names).

Evidence for the 16px body/input floor specifically — **not a design preference**: Safari on iOS
auto-zooms any input whose computed font-size is below 16px, which is disruptive and looks like a
bug. **Strong**, platform-mechanical fact, not an opinion. [CSS-Tricks: 16px or Larger Text
Prevents iOS Form Zoom](https://css-tricks.com/16px-or-larger-text-prevents-ios-form-zoom/). The
current `AppTextField._inputTextStyle` already uses `productBase` (16px in the current token
file) — correct value, wrong token *source* (see §0).

Material 3's five-role scale (display/headline/title/body/label, three sizes each) was reviewed
as a reference point but not adopted wholesale — it's Google's own system design, useful as a
naming convention, not independent evidence. **Moderate** (authoritative platform guidance, not a
controlled study). [Material 3 — Applying type](https://m3.material.io/styles/typography/applying-type)

### 1.3 Color

The website's `tokens.css` defines **one dark palette only** (it documents a single dark theme
as a deliberate choice; there is no `prefers-color-scheme` branch) — a light theme must be derived
by analogy, not copied. The dark values below are a direct port (Strong evidence); the light and
semantic values are derived here and their contrast ratios computed and WCAG-checked. They still
need a visual QA pass once rendered, but contrast compliance is not an open question.

**Dark theme** (direct port of the website's tokens):

| Role | Hex | Notes |
|---|---|---|
| `color-ground` (bg) | `#0B0E14` | Page background |
| `color-surface` (raised) | `#141A24` | Cards, dialogs, sheets, elevated rows |
| `color-edge` (border, decorative) | `#3C4657` | Hairlines, non-interactive dividers. Never on a focusable border (2.03:1 on ground — below the 3:1 WCAG 1.4.11 floor by design) |
| `color-ink` (text, primary) | `#E8EDF5` | 16.43:1 on ground |
| `color-muted` (text, secondary) | `#8F9BB0` | 6.88:1 on ground |
| `color-signal` (accent, graphic only) | `#5B6CFF` | Fills, focus rings, interactive borders — never body text below 18px |
| `color-signal-light` (accent, text) | `#A8B2FF` | Links, accent text |
| `color-on-signal` (text on filled accent) | `#0B0E14` (= ground) | Ink-on-signal is only 3.55:1, fails AA — filled buttons MUST use ground-colored text |

**Light theme.** The values below were computed against the WCAG 2.1 relative-luminance
contrast formula (not eyeballed), derived by hue-preserving lightness inversion from the
dark-theme hexes above so the two themes read as the same brand, not two unrelated palettes.
Still **not usability-tested** — they need a visual QA pass once rendered — but the AA contrast
checks are done:

| Role | Hex | Verified contrast |
|---|---|---|
| `color-ground` | `#F5F6FA` | — (page background) |
| `color-surface` | `#FFFFFF` | pure white card on a faint blue-grey page |
| `color-edge` | `#AEB8CA` | **1.85:1** on ground, **2.00:1** on surface — matched to the dark theme's own edge-on-ground band (2.03:1), same decorative-only role, never on a focusable border |
| `color-ink` | `#12151C` | **16.91:1** on ground, 18.26:1 on surface |
| `color-muted` | `#5B6478` | **5.49:1** on ground, 5.93:1 on surface |
| `color-signal` (accent, graphic only) | `#3B4FE0` | **5.75:1** on ground — darkened from the dark theme's `#5B6CFF` specifically so it clears AA on a light ground; still graphic/fill use only, not body text below 18px |
| `color-signal-light` (accent, text-safe) | `#2A3BC7` | **7.63:1** on ground, 8.24:1 on surface — for links/accent text below 18px, mirrors the dark theme's `signal-light` role |
| `color-on-signal` | `#FFFFFF` | **8.24:1** on `color-signal-light`; also clears AA on the graphic `color-signal` fill at button-label sizes (≥16px, 600 weight). White text on the accent works in the *light* theme, unlike the dark theme (which must use `ground`-colored text on its accent) — **this asymmetry is real and intentional**, document it in the token file so it doesn't read as a copy-paste error. |

**Semantic colors (danger/success/warning)** — the website has none (marketing site, no
forms/status states). The values below are computed and verified against the *new*
ground/surface pair.

| Role | Dark hex | Dark contrast | Light hex | Light contrast |
|---|---|---|---|---|
| `danger` | `#EF9A9A` (reused from the app's existing dark token, re-verified against the new ground) | **8.98:1** on `#0B0E14` | `#B3261E` (new) | **6.05:1** on `#F5F6FA` |
| `success` | `#81C784` (reused, re-verified) | **9.60:1** on `#0B0E14` | `#1E7A34` (new) | **5.00:1** on `#F5F6FA` |
| `warning` | `#FFB74D` (reused, re-verified) | **11.16:1** on `#0B0E14` | `#8A5300` (new) | **5.86:1** on `#F5F6FA` |

All six values clear WCAG AA (4.5:1) for normal text. `disabled`/`focus-ring`/`scrim`: reuse
`color-muted`/`color-ink`/a semi-transparent `color-ground` respectively per §1.4 — no separate
hex needed. Computation method: the standard WCAG 2.1 relative-luminance formula, run
independently for every pair above (cross-checked against the dark theme's own ratios as stated
in `tokens.css`'s comments, which reproduce exactly — e.g. `ink` on `ground` recomputes to
16.43:1, matching the file's own claim).

Dark-mode surface guidance: use a **dark grey, not pure black**, for ground/surface separation —
matches Material 3's own guidance and the website's actual choice (`#0B0E14`/`#141A24`, not
`#000000`). **Moderate** (vendor design-system guidance). [Material 3 — Color
roles](https://m3.material.io/styles/color/roles)

### 1.4 Border, radius, focus

- **Radius: 0 everywhere.** No `border-radius` token at all, except `50%` on true circles
  (avatars, status dots) — a fixed design rule, and also the one documented exception
  in the website's own chamfer system, so it survives the chamfer's removal unchanged.
- **Border width:** 1px decorative (`color-edge`, hairlines/dividers/static card borders), 2px
  interactive (`color-signal`/`color-focus-ring`, on hover/focus/error states) — simplified from
  the website's 1.5px/2px pair (the 1.5px only existed to survive its clip-path chamfer at
  fractional-pixel rendering; a plain square border doesn't need that fudge).
- **Focus ring:** 2px solid, `color-focus-ring` (proposed: reuse `color-signal`/darkened variant per
  theme), **outset** (not the website's `-4px` inset) — the inset trick existed solely to survive
  `clip-path` clipping on chamfered corners; with square corners a normal outset `outline` is both
  simpler and doesn't need a second painted layer. Must meet WCAG 1.4.11 (3:1 against adjacent
  colors) and 2.4.13 Focus Appearance's minimum area/contrast — **Strong**, W3C normative.
  [Understanding SC 2.4.13 Focus Appearance](https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html),
  [Understanding SC 1.4.11 Non-text Contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)

### 1.5 Components — current inventory vs. needs

`AppButton` (primary/secondary/destructive), `AppTextField`, `AppCheckbox`, `AppDialog`,
`AppSheet`, `AppListTile` are all present, headless, and token-driven — keep the API surface,
replace only the tokens they resolve. Missing (needed for this spec, listed in full in
`tokens-needed.md`): a shared **screen header** (title + back affordance — currently every screen
hand-rolls a full-width "Back" `AppButton`, see §3), heading/body **text style helpers** analogous
to `secondaryTextStyle()` for the new `h1`/`h2`/`h3`/`body`/`eyebrow`/`mono-data` roles, a
**progress/step indicator** for the sign-in flow, and an **OTP code field** variant of
`AppTextField`.

---

## 2. Per-screen specs

Each screen: purpose, layout at 390px/1280px, hierarchy, components + sizes, states, copy
guidance, evidence for non-obvious calls, then (§3) what's wrong today.

### 2.1 Bootstrap / splash

**Purpose.** Resolve version check → auth session → feature switches, then navigate away. Only
ever visibly renders two states: checking, and version-blocked.

**Layout (390 & 1280 — identical, this screen never needs a wide layout):**
```
┌─────────────────────┐
│                      │
│                      │
│      [app mark]      │   ← currently absent entirely
│    Checking…         │   body, centered
│                      │
└─────────────────────┘
```
Blocked state:
```
┌─────────────────────┐
│  [app mark]          │
│  Update required  h1 │
│  <message>       body│
│  [ Update ]     btn  │
└─────────────────────┘
```

**Hierarchy.** No H1 on the checking state (a logo mark + `body`-styled status line is enough —
this screen is on screen for well under a second in the common case). Blocked state: `h1` +
`body` + one full-width primary `AppButton`.

**Components.** `AppButton` (primary, full-width via `SizedBox(width: double.infinity)`, not
content-width).

**States.** checking (default) / blocked (with or without an update URL — currently handled) /
*(missing) timeout or network-failure state* — `BootstrapController`'s dartdoc says this screen
"only ever renders a blocked version check", meaning a stalled version/auth check has no visible
recovery UI; add a "Try again" fallback after a few seconds rather than an indefinite blank
"Checking…". This gap sits in the model/controller, not only in the visuals.

**Copy guidance.** "Checking…" → keep short; blocked title should name the action ("Update
required"), not the state ("App outdated").

### 2.2 Consent sheet

**Purpose.** §25 TDDDG-compliant equal-weight Accept/Reject, no pre-ticked box, Settings link.

**Layout (390):**
```
┌─────────────────────┐ 24px gutter
│ CONSENT         eyebrow (new)
│ We use cookies…  h1  │
│ <message>       body │
│                      │
│ [ Reject ] [ Accept ]│ ← equal width, equal variant
│                      │
│   Manage in Settings │ ← tertiary/link-style, not a bordered button
└─────────────────────┘
```
**Layout (1280):** same content, centered in a 440px column (this is a dialog-weight decision,
not a list screen) — never a full-bleed 1280px-wide sheet.

**Hierarchy.** `h1` title, `body` message, two co-equal buttons, one link-weight tertiary action
(Settings) below — visually subordinate to the two consent buttons, but not hidden.

**Components.** Two `AppButton`s **same variant, same size** (the code already gets this right —
both use `AppButtonVariant.secondary`, see §3.2 for the actual visual problem this creates), one
text-link-style action for Settings (currently also a bordered `AppButtonVariant.secondary`
button — should not look like a third equal-weight choice).

**States.** No loading/error state exists or is needed — this is a local preference write, not a
network call.

**Copy guidance.** Reject and Accept labels must be equal length/register ("Reject all" /
"Accept all", not "No thanks" / "Accept").

**Evidence.** Equal-weight buttons + no pre-tick: **Strong**, both empirical HCI research
(Nouwens et al., Utz et al.) and binding case law (Planet49 ECJ C-673/17, LG München I).

### 2.3 Sign-in — email → code

**Purpose.** Email-first OTP sign-in; passkey/Apple/Google behind switches; App Review demo
path; never reveals account existence.

**Layout (390), email step:**
```
┌─────────────────────┐
│ Sign in          h1  │
│                      │
│ Email          label │
│ [______________]     │ 44px min-height, 16px text
│                      │
│ [ Continue ]         │ full-width primary
│                      │
│ ── or ──             │
│ [ Continue with Apple]   secondary, full-width
│ [ Continue with Google]  secondary, full-width
│ [ Sign in with passkey]  secondary, full-width
│                      │
│ Legal · Terms · Privacy │  text links, not buttons
└─────────────────────┘
```
Code step: replace the email field with a 6-digit `mono-data` code field (single input, not 6
boxes — see evidence below) + "Resend code" (disabled, countdown) + "Change email" (tertiary).

**Layout (1280):** centered 440px column, same vertical order — **not** a split-screen
illustration layout (no evidence was found to justify the extra design/build cost for this app's
scope; the secondary sources surveyed for login-form width converge on a single centered column,
not a split layout).

**Hierarchy.** `h1` "Sign in" once. Primary action = email submit / code verify (primary
variant, full-width). Passkey/Apple/Google = secondary variant, full-width, stacked below a
visual divider — never crammed into the same row as email entry. Legal links = plain text links
in a footer row, not bordered buttons (see §3.3).

**Components.** `AppTextField` (email; code, `mono-data` style), `AppButton` primary
(full-width) for submit, `AppButton` secondary (full-width) × N for alternates, a new "resend
timer" affordance (not currently a component), text-link row for legal.

**States.** empty / typing / submitting (loading spinner on the primary button — already wired)
/ error (generic, invalid code, rate-limited — already modeled in `SignInError`) / success
(navigates away, no visible success state needed).

**Copy guidance.** Error text must never say "no account with that email" (sign-in never
reveals whether an account exists) — keep the generic error copy path that's already in
`SignInError.generic`.

**Evidence:**

| Call | Evidence | Strength |
|---|---|---|
| Label above the field, not floating/placeholder-only | Baymard's mobile-checkout study (18 sites, 1000+ fields): labels must stay visible once typing starts; floating/placeholder-only labels disappear exactly when needed for error recovery | **Strong**. [Baymard: Field Label UX](https://baymard.com/blog/mobile-form-usability-label-position), [NN/g: Placeholders in Form Fields Are Harmful](https://www.nngroup.com/articles/form-design-placeholders/) |
| Input font-size ≥16px | Prevents iOS Safari's auto-zoom-on-focus | **Strong**, mechanical fact | 
| OTP: one field with `autocomplete="one-time-code"`/`autofillHints`, not 6 boxes | A single field keeps SMS autofill, screen-reader semantics, paste, and undo; 6-box implementations routinely lose all of these while adding custom focus-shuffling logic | **Moderate–Strong** — consistent practitioner consensus (Twilio, Cloud Four) rather than a single controlled study, but the mechanism (autofill/paste/a11y loss) is verifiable, not opinion. [Twilio: Best Practices for OTP Input Forms](https://www.twilio.com/en-us/blog/developers/best-practices/best-practices-for-otp-input-forms-in-ios), [Cloud Four: Simple One-Time Passcode Inputs](https://cloudfour.com/thinks/simple-one-time-passcode-inputs/) |
| Primary button full-width on mobile | Maximizes tap target, single unambiguous primary action | **Moderate** — repeated practitioner guidance, not a single controlled A/B result. [Baymard: Button Design](https://baymard.com/blog/button-design) |
| Social buttons stacked below email, Apple ≥ equal prominence to Google when both shown | Apple App Store Guideline 4.8 requires equivalent prominence for Sign in with Apple whenever a third-party social login is offered | **Strong** (binding platform policy) |
| Error message directly below the field it belongs to | Lower cognitive load than above-field or top-of-form summaries; stated user preference for below/beside placement | **Strong**, NN/g. [NN/g: 10 Design Guidelines for Reporting Errors](https://www.nngroup.com/articles/errors-forms-design-guidelines/) |
| Resend-code cooldown ~30–60s with a visible countdown, never fully hidden | Practitioner convention; prevents spam/rate-limit hits while keeping the option discoverable | **Weak** — no controlled study found, vendor/blog sources only |
| Legal links as plain text, not bordered buttons, placed in the footer | No direct study found for this specific placement; kept because three bordered secondary buttons in a row at 390px width overflow (see §3.3) | **Weak** — practical/technical necessity, not research |

### 2.4 Onboarding — checklist + optional personalization

> **Superseded by the approved mockups (2026-09-26):** onboarding is a **profile setup stepper** (Profile → Preferences → Notifications, steps defined per app), plus a "Finish your setup" card on Home; see the `Onboarding*` and `Home*` artboards in `mockups/`. The checklist text below is kept for context only.

**Purpose.** Empty states + a dismissible checklist, no carousel; optional personalization step.

**Layout (390):**
```
┌─────────────────────┐
│ Welcome          h1  │
│ Get started      h2  │
│ ☐ Complete your profile
│ ☐ Turn on notifications
│ ☐ Explore the app    │
│ [ Done ]              full-width secondary
│                      │
│ (if personalization) │
│ Personalize      h2  │
│ <hint>          body │
│ Name          label  │
│ [____________]       │
│ [Skip] [Continue]    │  equal-width pair
└─────────────────────┘
```

**Hierarchy.** `h1` welcome title, `h2` "Get started", checklist rows use `AppCheckbox` (see
§3.4 — currently plain text, not even a checkbox), then the dismiss action.

**Components.** `AppCheckbox` × 3 (checked state reflects real per-user progress, not just
decoration — if the model doesn't track per-item completion yet, that's a model gap as well as
a visual one), `AppButton` secondary (dismiss), `AppTextField` +
`AppButton` pair (personalization).

**States.** checklist items should visually distinguish done vs. not-done (currently none do,
see §3.4); personalization section shown/hidden by `AppConfig.personalization`, already modeled.

**Evidence.** No carousel/tutorial: **Strong**, NN/g controlled study. Empty-state-as-onboarding
pattern generally: **Strong** for the "avoid forced tutorials" half, **Moderate** for the
specific checklist mechanic (NN/g's empty-state framework is about system
status/learnability/task pathways, not a checklist-widget-specific study). [NN/g: Designing Empty States in Complex Applications](https://www.nngroup.com/articles/empty-state-interface-design/)

### 2.5 Permission pre-prompt

**Purpose.** In-context value framing before the real OS permission dialog (push/ATT/location),
never mimicking the system dialog.

**Layout (390, as a dialog, not full-screen):**
```
┌─────────────────────┐
│ Stay in the loop  h3 │
│ <value-framed msg> body
│ [Not now] [Continue] │  equal-width, Continue = primary
└─────────────────────┘
```

**Hierarchy.** `h3` (dialog-weight, not a full `h1` screen title — this is a modal), body
message, two-button row. "Continue" is legitimately primary here (unlike consent) because this
is not a legal equal-weight requirement — declining has no dark-pattern risk the way a
pre-selected cookie choice would.

**Components.** `AppDialog` (already used), text only, two `AppButton`s (secondary "Not now",
primary "Continue").

**Copy guidance.** Value-first framing ("See when your order ships" rather than "Allow
notifications?") — Apple's own guidance explicitly permits soft "Got it"/"Next"-style copy here,
but forbids anything that pressures or mimics the system alert's chrome.

**Evidence.** Showing a pre-prompt at all, in-context, non-mimicking: **Moderate** — this is
Apple's own stated interaction pattern (an official platform guideline, not a vendor claim), but
the *conversion-rate* case for doing it is vendor-sourced and unverified, so the copy/framing
choice stays rated **Weak**; only the *existence of the pattern itself* rates Moderate, since it
is traceable to Apple's own HIG page, not just marketing blogs. [Apple HIG:
Requesting Permission](https://developer.apple.com/design/human-interface-guidelines/privacy)

### 2.6 Home (signed-in landing)

**Purpose.** Post-sign-in landing with an empty state and entry points to Settings/sign-out.

**Layout (390):**
```
┌─────────────────────┐
│ Home         [Settings]│ h1 left, icon-button right
│                      │
│     <empty-state     │
│      illustration+   │
│      copy>           │
│                      │
│ [ Sign out ]         │  secondary, full-width, bottom
└─────────────────────┘
```
**Layout (1280):** content column capped at 960px, centered; header spans full width.

**Hierarchy.** `h1` "Home" + icon-only settings affordance (currently a full text "Settings"
button — fine on mobile, but should become an icon button once the header component exists, see
§3.6). Empty-state body copy is the visual center of the screen. Sign-out is bottom-anchored,
low emphasis (secondary), since it's rare and slightly destructive-adjacent.

**Components.** New header component (title + trailing icon action), empty-state block (icon or
simple graphic + `h2`/`body` copy + optional CTA — currently text-only, no icon/illustration at
all), `AppButton` secondary.

**States.** empty (default, since this is a template) / populated (a cloned app fills this in —
out of scope for the template itself, but the empty state must not look broken when it's the
*permanent* state for apps that never fill it in).

**Evidence.** Empty-state framework (communicate status, teach, give a task path): **Strong**,
NN/g — same source as §2.4.

### 2.7 Settings hub

**Purpose.** Legal / Privacy / Account / (switch) Subscription — the entry list.

**Layout (390):**
```
┌─────────────────────┐
│ ← Settings           │  header: back-chevron + h1, one row
│                      │
│ Legal              › │  AppListTile, 44px+ row
│ Privacy            › │
│ Account            › │
│ Subscription       › │  (if paywall switch on)
└─────────────────────┘
```
**Layout (1280):** list column capped at 640px, centered.

**Hierarchy.** One `h1` in a shared header row, list of `AppListTile`s with trailing chevrons —
no section headers needed at only 3–4 items, but the header/list-row pattern must be identical
across every settings/legal screen (currently each screen re-implements its own back button and
title padding independently — see §3.7).

**Components.** New shared header (back-chevron icon button + `h1`, single 44px+ row, not the
current full-width "Back" text button stacked above the title), `AppListTile` × N with a
trailing chevron icon (currently no trailing content is passed at all — see §3.7).

**Evidence.** iOS/Android convention for a back-chevron + title header row over a full labeled
button: standard platform convention on both reference platforms; no single controlled study, but
overwhelming convention. **Moderate**. Grouped/sectioned list convention for settings screens
generally (not yet needed at this item count, but documented for when Settings grows):
[Material 3 — Lists](https://m3.material.io/components/lists/guidelines).

### 2.8 Legal hub

Same shell as Settings hub (§2.7): header + `AppListTile` list (Impressum, Datenschutz, AGB,
optional Barrierefreiheit, Licences). Reachable in ≤2 taps pre-login per the flow requirement —
unaffected by this visual spec, already satisfied at the navigation-graph level.

### 2.9 Legal document (Impressum/Datenschutz/AGB/Barrierefreiheit)

**Purpose.** Render one legal document from `AppConfig` facts, in clearly marked template text.

**Layout (390 & 1280 — this is the one screen where the 1280 layout genuinely differs in
substance, not just centering):**
```
390:                          1280 (measure-capped, NOT full 1280 width):
┌─────────────────┐          ┌───────────────────────────────┐
│ ← Impressum      │          │ ← Impressum                    │
│                  │          │                                 │
│ <template notice>│          │        <content column,        │
│ <intro>          │          │         max-width ~65ch,        │
│ Company: …       │          │         centered>               │
│ Address: …       │          │                                 │
│ …                │          └───────────────────────────────┘
└─────────────────┘
```

**Hierarchy.** `h1` document title, `caption`-styled "template notice" (currently the same
weight as body text — should read as a footnote, not a peer paragraph), `body` intro, then a
fact list (label/value pairs, currently a flat `"${label}: ${value}"` string with no visual
separation — should be a two-column or stacked label/value pair per row, label in `eyebrow` or
`body-sm`/muted, value in `body`).

**Components.** New header, `body`/`caption`/`h1` text styles, a fact-row layout (new — no
current component covers a definition-list-style row).

**Copy guidance.** Template-notice text must stay visually subordinate (caption weight, muted
color) so it doesn't compete with the actual legal content for a reader who came here to find an
address or a VAT ID.

**Evidence.** 65ch measure cap: **Strong**, see §1.1 (Baymard + Bringhurst). This is the
screen where the missing max-width most directly hurts usability — at 1280px, unconstrained body
text is currently one line spanning ~150+ characters (see §3.9).

### 2.10 Licences (OSS)

**Purpose.** `LicenseRegistry.licenses`-driven list, package name + full licence text + copy
button per entry.

**Layout (390):**
```
┌─────────────────────┐
│ ← Licences            │
│                      │
│ package-name    ›    │  AppListTile, collapsed by default
│ package-name    ›    │
│ …                    │
└─────────────────────┘
```
Tapping a row opens the full licence text (new: a detail sub-screen or expandable disclosure),
**not** inline full-text blocks stacked in the list as today.

**Hierarchy.** `h1` header, list of package names (`body`, or `mono-data` since these are
identifiers), full licence text moved off the list screen — licence texts run to hundreds of
lines; showing them inline turns a scan-able list into an unusable wall of text.

**Components.** `AppListTile` (title = package name(s), trailing chevron), a new detail view or
`AppSheet` for the full text (monospace, `mono-data`, in its own scrollable region), copy button
stays on the detail view.

**States.** loading (currently: **no spinner is rendered at all** — see §3.10) / empty (already
handled) / populated.

**Copy guidance.** none needed beyond the licence text itself (verbatim, required as-is).

### 2.11 Privacy settings — consent change + data export (step-up)

**Purpose.** Change consent at any time; export data behind step-up re-authentication.

**Layout (390):**
```
┌─────────────────────┐
│ ← Privacy             │
│                      │
│ Consent          h2  │
│ Status: Accepted body│
│ [Reject] [Accept]    │  equal-weight pair, same as §2.2
│                      │
│ Export your data  h2 │
│ <description>    body│
│ [ Export ]            primary, full-width
│  (step-up):           │
│  Code           label │
│  [__________]         │
│  [ Verify & export ]  │
│  (result):             │
│  [ Copy ]              │
│  { …json… }            mono-data, in a bordered/scrollable block
└─────────────────────┘
```

**Hierarchy.** Two `h2` sections under one `h1`/header. Consent status shown as `body` text
today (currently no visual state indicator — a colored status chip using `eyebrow` style would
read faster than a sentence, see §3.11). Export flow is a linear state machine
(idle → step-up → exporting → result) already modeled in `ExportPhase` — each phase needs a
distinct visual treatment, especially the result JSON, which today is **plain wrapped body text**
dumping raw JSON with no monospace font, no scroll container, no line breaks respected.

**Components.** `AppButton` pair (consent, equal-weight, same pattern as §2.2), `AppButton`
primary (export), `AppTextField` (step-up code, `mono-data`), a new bordered/scrollable
**code block** component for the JSON result (currently missing entirely).

**States.** idle / stepUp / exporting (loading spinner on submit — already wired via
`model.exportPhase == ExportPhase.exporting`) / result. All four already exist in
`PrivacySettingsModel`/`ExportPhase` — this is a pure visual gap, not a missing state.

### 2.12 Account settings — identities + delete account

**Purpose.** Disconnect linked social identities; delete account (confirm → real deletion, no
ticket).

**Layout (390):**
```
┌─────────────────────┐
│ ← Account             │
│                      │
│ Linked accounts   h2 │
│ Google            [Disconnect]
│ (empty: "No linked accounts")
│                      │
│ ──────────────────── │  visual separation before the danger zone
│ [ Delete account ]    destructive, full-width
└─────────────────────┘
```
Delete confirmation (`AppDialog`, already exists):
```
┌─────────────────────┐
│ Delete your account?  h3
│ <irreversible-warning>│
│ [ Cancel ] [ Delete ] │  Cancel = secondary & default-focused,
└─────────────────────┘    Delete = destructive
```

**Hierarchy.** Identities list first, then a visually separated "danger zone" — currently the
delete button sits directly below the identities list with only a `SizedBox(height: 24)` gap and
no visual boundary (divider/section label), so it doesn't read as a distinct, weightier zone.

**Components.** `AppListTile` (identity rows, trailing `AppButton` secondary "Disconnect" —
already implemented), a divider or section boundary before delete (new), `AppButton`
destructive, `AppDialog` confirmation (already implemented, already uses `destructive` variant
correctly).

**States.** loading (no visible spinner while `model.loading`, same gap pattern as Licences, see
§3.12) / empty ("No linked accounts", already handled) / populated.

**Evidence — confirmation pattern:**

| Call | Evidence | Strength |
|---|---|---|
| A confirmation dialog restating the action + consequence, safe action (Cancel) focused by default | NN/g: dialogs prevent slips, not mistakes — the copy must restate what will happen, and focus should never default to the destructive action | **Strong**, NN/g. [NN/g: Confirmation Dialogs Can Prevent User Errors](https://www.nngroup.com/articles/confirmation-dialog/) |
| Type-to-confirm ("type DELETE" / the account email) for account deletion specifically | Reserved for the most serious, irreversible actions — account deletion is a commonly cited example | **Weak-Moderate** — practitioner consensus, no controlled A/B test found comparing type-to-confirm vs. a plain two-button dialog for conversion or error-prevention specifically on *account deletion* | 

**Recommendation given the evidence.** The design already commits to "delete account without a
ticket step" as a *flow* decision (fewer steps, not more) — a type-to-confirm text field would
add a step and cuts directly against that decision, on evidence that's itself only Weak-Moderate.
**Keep the existing two-button `AppDialog` pattern** (Cancel default-focused / Delete
destructive-styled), do not add type-to-confirm. This is a deliberate decision, not an
oversight.

### 2.13 Paywall (stub)

**Purpose.** Placeholder subscription screen with Apple 3.1.2 disclosures; no real billing.

**Layout (390):**
```
┌─────────────────────┐
│ ← Subscribe            │
│                      │
│ <plan name>      h2  │
│ €X.XX          display │  price gets real visual weight
│ per <period>    body │
│ <auto-renew notice> caption
│ [ Subscribe ]         primary, full-width (stub: disabled or no-op)
│ Terms · Privacy       text links, footer
└─────────────────────┘
```

**Hierarchy.** Price is the one place `display` (32px) is used outside this spec's general
scale — it's the number a paywall lives or dies on. Auto-renew/disclosure text at `caption`
weight, still fully legible (Apple 3.1.2 requires it be present and clear, not necessarily loud).

**Components.** same header, `display` price text (new), `caption` disclosure text, `AppButton`
primary, text-link footer (same pattern as sign-in's legal row — see §3.13, current version
reuses bordered secondary buttons here too).

---

## 3. What's wrong with the current screens (from reading the code)

Each finding cites file:line in the code as it stood when this spec was written. Grouped by
pattern first (appears almost everywhere), then per-screen specifics.

**Pattern A — no typographic hierarchy anywhere.** Every screen uses raw `Text(t.foo.bar)` for
titles, body copy, hints, and errors, with zero explicit style. Flutter's default `Text` with no
ambient `DefaultTextStyle` from a Material/Cupertino app shell renders in whatever fallback style
`flutter/widgets.dart` provides — no font family, default black-ish color, ~14px. Confirmed
present in **every one of the 13 view files read** (e.g. `bootstrap_view.dart:45,50,52`,
`consent_view.dart:39,41`, `sign_in_view.dart:155,45,77`, `onboarding_view.dart:41,43`,
`home_view.dart:42,56`, `settings_hub_view.dart:45`, `legal_document_view.dart:107,109,111,116`,
`licences_view.dart:45,85,87`, `privacy_settings_view.dart:141,145,147`,
`account_settings_view.dart:72,76`, `paywall_view.dart:50,52,54,55,57`). None of the six real
components in `core/design/ui` are missing this — `secondaryTextStyle()` exists and is correctly
used inside `AppTextField`/`AppListTile` — but no equivalent exists for a page title or body
paragraph, so screens never reach for one.

**Pattern B — no shared header; "Back" is a full-width bordered button repeated seven times.**
`settings_hub_view.dart:34-41`, `legal_hub_view.dart:33-40`, `legal_document_view.dart:94-101`,
`licences_view.dart:34-41`, `privacy_settings_view.dart:128-135`,
`account_settings_view.dart:61-68`, `paywall_view.dart:37-44` all independently construct:
```dart
Padding(padding: const EdgeInsets.all(16), child: AppButton(
  semanticLabel: t.common.back, onPressed: controller.goBack,
  variant: AppButtonVariant.secondary, child: Text(t.common.back)))
```
— a full-width-capable, 44px-tall, bordered button whose label is the single word "Back", stacked
*above* the screen title as its own row. On every settings/legal screen this reads as two stacked
header elements (a button, then a separate untitled text row) rather than one navigation bar. No
back-chevron icon exists anywhere in the codebase.

**Pattern C — no max-width constraint on any screen.** Every screen's root is
`SafeArea > Column`/`ListView` with no `ConstrainedBox`/`Center` wrapping — at 1280px (desktop/
web), list rows, buttons, and body text all stretch edge-to-edge. This is most damaging on
`legal_document_view.dart` (body text at unconstrained width, see §2.9) and `sign_in_view.dart`
(a form control stretching to 1280px wide).

**Pattern D — primary submit buttons are content-width, not full-width, outside of
equal-weight-pair rows.** `AppButton` itself sizes to its content (`Center(child: child)` inside
a `ConstrainedBox` with only a *minimum* 44×44, `button.dart:88-96`) — correct component
behavior, but no calling screen wraps a lone primary button in `SizedBox(width: double.infinity)`
or an `Expanded` parent. Confirmed at `sign_in_view.dart:37-42` (request-code), `:52-57`
(verify-code), `privacy_settings_view.dart:68-72` (export). Where buttons *are* full-width today,
it's incidental (they're inside a `Row` + `Expanded` equal-weight pair, e.g. consent, onboarding
personalization, permission pre-prompt) — there's no full-width single-button pattern anywhere.

**Pattern E — no loading spinner rendered for a `loading` field that exists in the model.**
`licences_view.dart:47-60`: the ternary only branches on
`model.entries.isEmpty && !model.loading` (empty text) vs. else (`ListView.builder` over
`model.entries`) — while `model.loading == true` and `entries` is still empty, this falls into
the `ListView.builder` branch with `itemCount: 0`, rendering a blank area, not a spinner.
Identical pattern at `account_settings_view.dart:24-29`: `if (!model.loading &&
model.identities.isEmpty)` only covers the empty-and-not-loading case — while loading, nothing
renders in that section at all.

Per-screen specifics not already covered above:

- **2.1 Bootstrap:** no app mark/branding at all in `bootstrap_view.dart` — a "Checking…" line on
  a blank canvas (`:45`). No visible recovery path if the version/auth check stalls (see §2.1).
- **2.2 Consent:** the two buttons *are* correctly equal-weight (`consent_view.dart:49-64`, both
  `AppButtonVariant.secondary`) — genuinely compliant with the legal requirement. The visual
  problem is that **both being `secondary`** means the entire decision reads as low-emphasis
  (outlined, no fill) — the design fix is not to make one more prominent (that would violate the
  requirement) but to consider whether a third, distinct "equal-emphasis-but-filled" button
  treatment is worth adding to `AppButtonVariant` (see `tokens-needed.md`). The Settings link
  (`:68-73`) is *also* rendered as a full bordered `AppButtonVariant.secondary` button — visually
  indistinguishable from Accept/Reject, which risks reading as a third consent option rather than
  a subordinate link; should be demoted to a text-link style once one exists.
- **2.3 Sign-in:** the three legal links (`_LegalLinksRow`, `sign_in_view.dart:206-233`) are each
  a full bordered `AppButtonVariant.secondary` button in one `Row` with no `Wrap`/scroll fallback
  — at 390px width, three 44px-min-height bordered buttons with 32px total horizontal padding
  each plus label text ("Legal"/"AGB"/"Datenschutz") plus two 8px gaps is a **real overflow risk**
  that should be checked against actual rendered widths, not just asserted; regardless of whether
  it literally overflows, it is definitely visually heavier than a footer of three should be.
  Alternative sign-in methods (`_alternativeSignInMethods`, `:106-133`) render passkey/Apple/
  Google/reviewer all as identical bordered secondary buttons with plain text labels — no
  provider iconography (Apple/Google logo marks), which is both a platform-recognition
  convention miss and, for Apple specifically, a guideline nuance (4.8 asks for equivalent
  prominence, which plain identical text buttons technically satisfy, but real apps almost always
  use the vendor mark).
- **2.4 Onboarding:** checklist rows (`_ChecklistRow`, `onboarding_view.dart:127-145`) are plain
  `Text` in a `Padding` — no checkbox glyph, no strike-through/done state, nothing that visually
  says "checklist" rather than "bullet list". `AppCheckbox` exists and is unused here.
- **2.6 Home:** `home_view.dart:52-59` empty state is `Center(child: Padding(child: Text(...)))`
  — text only, no icon/illustration, no secondary CTA suggesting what to do next; NN/g's
  empty-state framework calls for a task pathway, which is absent here.
- **2.9 Legal document:** `_facts` are rendered as one interpolated string per row
  (`'${fact.label}: ${fact.value}'`, `:116`) with no visual separation between label and value —
  a scanning reader (looking for the VAT ID, say) has to read every line's full sentence rather
  than scan a label column.
- **2.10 Licences:** full licence text is rendered inline in the list
  (`_LicenceEntryTile`, `licences_view.dart:79-98`) — for any real OSS licence set this produces
  a multi-thousand-line scroll of legal text interleaved with package names, effectively
  unusable as a "list".
- **2.11 Privacy settings:** exported JSON (`Text(model.exportedJson ?? '')`,
  `privacy_settings_view.dart:104`) renders as wrapped proportional-font body text — no
  monospace, no scroll container, no syntax structure; consent status
  (`_consentStatusText`, `:23-27`) is a plain sentence with no visual state indicator (color/chip).
- **2.12 Account settings:** no visual separation between the identities list and the destructive
  delete-account button beyond a `SizedBox(height: 24)` (`:79`) — no divider, no section label,
  no color/spacing signal that this is a different risk tier of action.
- **2.13 Paywall:** price and period are two separate plain `Text` widgets
  (`paywall_view.dart:54-55`) with no visual hierarchy between them and the plan title — nothing
  in this screen currently looks like a priced product.

No `TODO`/`FIXME` comments were found in any of the 13 view files read.
