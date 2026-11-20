# Tokens and components spec.md needs that `core/design/ui` currently lacks

Companion to `spec.md`, kept close to machine-readable. Format: one item per bullet, with
current-state / needed-state / source. "Current state" cites the file as it stood when the spec
was written; "needed" is what the spec (§1–§2) assumes exists. Nothing here had been implemented
at the time of writing — this is the work list for the token file and component additions. "The
website" means the reference site whose type system and dark palette spec.md adopts; it is not
part of this repository.

## A. Token file replacement (`core/design/ui/tokens/*.json`)

The entire current token set must be replaced, not merged — it's copied from a diagram/
architecture-drawing design system, not authored for this app.

- [ ] `typography.json` → `font.family.title/body/mono`: currently `Instrument Serif` /
      `Geist` / `Geist Mono`. Needed: `Host Grotesk` (title+body) / `IBM Plex Mono` (mono). Also
      drop the entire `typography.*` block (diagram-label scale: 7.5–14px, not a product scale)
      and replace `product.*` (currently a minor-third ramp: 12/14/16/18/20/24/30/36px) with
      spec.md §1.2's role-named scale: `display` 32 / `h1` 24 / `h2` 20 / `h3` 16 / `body` 16 /
      `body-sm` 14 / `caption` 12 / `eyebrow` 14 (**Host Grotesk 600, uppercase, 0.04em
      tracking — not mono; see the eyebrow note in spec.md §1.2**) /
      `mono-data` 16 / `button` 16.
- [ ] `dimension.json` → `radius.sm/md/lg`: currently 4/6/8px. Needed: all `0`, plus a `full`
      token (`9999px` or `50%` equivalent) reserved for true circles (avatars, status dots).
      `space.*` scale (4/8/12/16/24/32/48/64px, currently already correct in *structure* —
      4/8/12/16/24/32/48/64 — keep as-is, it matches the website's `--space-1..8`). `stroke.*`
      (currently thin 0.8px / default 1px / strong 1.2px) → needed: decorative 1px / interactive
      2px (see spec.md §1.4 — simplified from the website's 1.5/2px pair since square corners
      don't need the chamfer-survival fudge factor).
- [ ] `color.dark.json` / `color.light.json`: full replacement. Current file is the diagram
      system's palette (`paper`/`paper-2`/`ink`/`muted`/`soft`/`rule`/`accent`/`series-1..5`/
      `tier-security..archive`/`ink-band`/`ink-deep` — none of this belongs in a product UI).
      Needed roles: `ground`, `surface`, `edge` (border), `ink` (text primary), `muted` (text
      secondary), `signal`/`accent` (graphic-only accent), `signal-light`/`accent-text` (text-safe
      accent), `on-signal`/`on-accent` (text-on-filled-accent — **differs by theme**, see
      spec.md §1.3), `danger`, `success`, `warning`, `disabled`, `focus-ring`, `scrim`. Dark-theme
      values are direct-ported from the website's `tokens.css`. Light-theme values and all six
      semantic colors (danger/success/warning × dark/light) are final: every hex in spec.md §1.3
      has been computed and verified against the WCAG 2.1 relative-luminance formula, against
      the *new* `#0B0E14`/`#141A24` (dark) and `#F5F6FA`/`#FFFFFF` (light) ground/surface pairs
      specifically (not carried over from the old app tokens' stale ratios, which were computed against the
      *old* `#2d3142`/`#3a4059` pair and don't transfer). Still needs a real *visual* QA pass once
      rendered — contrast math isn't the same as "looks right" — but the compliance work is done.
- [ ] `semantic.color.json`: structurally fine (`bg`→`{color.paper}`, `fg`→`{color.ink}`, etc.) —
      just needs its `$value` refs repointed once the base palette above is replaced. No rename
      needed if `ground`/`ink`/`edge`/`surface`/`muted` naming is kept consistent with spec.md.
- [ ] `motion.json` / `semantic.motion.json`: not reviewed in depth for this spec (out of visual
      scope) — the website's own `--duration-fast/base/slow/reveal` (150/200/350/550ms) and
      `--ease-out/in-out/in` cubic-beziers are a reasonable source to check against if the
      current motion tokens turn out to also be diagram-system leftovers; not confirmed either
      way here.

## B. New components / component additions (`core/design/ui/lib/src/components/`)

- [ ] **Screen header** (new component, e.g. `AppScreenHeader`). Back-chevron icon button + `h1`
      title in one 44px+ row. Replaces the current pattern of a full-width text "Back" `AppButton`
      stacked above a separately-padded title `Text`, independently duplicated in 7 screens (see
      spec.md §3, Pattern B, with file:line citations). Needs an icon-button variant of tappable
      chrome — `AppButton` currently has no icon-only mode (always wraps a `child` + requires
      `semanticLabel`, which works for an icon button, but there's no built-in chevron glyph or
      icon-sizing convention).
- [ ] **Heading/body text style helpers**, analogous to the existing
      `internal/text_styles.dart`'s `secondaryTextStyle()`. Needed: `h1Style()`, `h2Style()`,
      `h3Style()`, `bodyStyle()`, `bodySmStyle()`, `captionStyle()`, `eyebrowStyle()`,
      `monoDataStyle()` (or equivalent `StyledText`-ready `TextStyler`s), so screens stop calling
      raw `Text()` (see spec.md §0 and §3, Pattern A — present in all 13 screens).
- [ ] **OTP / code input.** A `mono-data`-styled variant of `AppTextField` (or a dedicated
      `AppCodeField`) for the 6-digit sign-in code and the privacy-export step-up code — single
      input field (not 6 boxes, see spec.md §2.3 evidence table), needs
      `autofillHints: [AutofillHints.oneTimeCode]` wiring (Flutter's equivalent of
      `autocomplete="one-time-code"`) which `AppTextField` doesn't currently expose at all
      (`text_field.dart` has no `autofillHints` parameter).
- [ ] **Resend-code timer/cooldown affordance.** Not currently a component or a controller-level
      concept found in `sign_in_controller.dart`/`sign_in_model.dart` — needed for the code-entry
      step (spec.md §2.3). Needs both a visual treatment (disabled button + countdown text) and
      confirmation that the controller models the cooldown at all.
- [ ] **Status chip / badge**, `eyebrow`-styled, for consent status ("Accepted"/"Rejected"/"Not
      set" in Privacy Settings, spec.md §2.11) and potentially the onboarding checklist's
      done/not-done state. Not currently in the component set.
- [ ] **Code block** (scrollable, monospace, bordered container) for the exported-data JSON
      result in Privacy Settings (spec.md §2.11) — currently `Text(model.exportedJson ?? '')`
      with no container at all.
- [ ] **Fact/definition row** (label + value, label visually subordinate) for the Legal Document
      screen's company facts (spec.md §2.9) — currently one interpolated string per row.
- [ ] **`AppListTile` trailing-chevron convention.** The component already supports a `trailing`
      slot (`list_tile.dart:42`), but no screen currently passes a chevron into it for
      navigational rows (Settings hub, Legal hub, Licences) — this is a call-site gap, not a
      component gap, but worth listing since every navigational list in the spec assumes a
      trailing chevron is present.
- [ ] **`AppButtonVariant` — consider a fourth "equal-emphasis filled" variant** for the consent
      screen (spec.md §2.2/§3): the legal requirement is *equal weight between the two consent
      buttons*, not *low emphasis* — today both Accept/Reject use `secondary` (outlined, no
      fill), which is compliant but reads as a low-stakes screen. Whether to add a variant or
      just theme `secondary` more assertively for this one screen is a design call for the
      mockup stage and is left open here.
- [ ] **Divider / section-boundary primitive.** Used implicitly in spec.md §2.12 (Account
      Settings' "danger zone" separation) and anywhere a settings screen grows past a handful of
      `AppListTile`s into sectioned groups (spec.md §2.7 evidence note on Material 3 grouped
      lists). No such primitive exists today — sections are currently separated only by
      `SizedBox` gaps.

## C. Layout primitives (app-level, not necessarily `core/design/ui`)

- [ ] A **max-width-constrained content wrapper** (`Center` + `ConstrainedBox`) applied at the
      screen-shell level — currently **zero** of the 13 screens constrain width, so every screen
      stretches edge-to-edge at desktop/web widths (spec.md §3, Pattern C). Needs three presets
      per spec.md §1.1: 440px (auth/dialog), 640px (settings/list), ~65ch (long-text/legal),
      960px (home/dashboard).
- [ ] A **full-width single-button wrapper** convention (`SizedBox(width: double.infinity)`) for
      lone primary CTAs outside of equal-weight button rows — currently inconsistent (only
      present incidentally inside `Row`+`Expanded` pairs; every lone primary submit button is
      content-width, spec.md §3 Pattern D).

## D. Explicitly NOT ported from the website (listed so the omissions read as deliberate)

- The clip-path **chamfer** system (`--chamfer`, `--chamfer-sm`, `--chamfer-border-min/
  interactive`, the two-layer "frame + hole" button construction) — square corners only, by
  design. `border-radius: 0` is a strict *simplification* of the chamfer system, not
  an approximation of it.
- The website's `-4px` **inset** focus-ring offset — that existed only to survive `clip-path`
  clipping. A normal outset focus ring is simpler and correct once corners are square (spec.md
  §1.4).
- Any of the website's `series-*`/`tier-*`/chart-oriented color tokens — those belong to
  a separate diagramming design system, never to this app; do not copy them "just in case".
