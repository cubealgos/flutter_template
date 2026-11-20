# Changelog

All notable changes to `ui` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged `ui-vX.Y.Z` (see
`docs/releasing.md`).

## [Unreleased]

### Fixed

- Every tappable control (`AppButton`, `AppIconButton`, `AppTextLinkButton`, `AppCheckbox`,
  `AppListTile`, text fields, the dismiss button, the screen header row) now has a 48 dp minimum
  hit target instead of 44, clearing `androidTapTargetGuideline`.

### Added

- `AppGap`: a fixed empty gap sized by a `space*` token, with a vertical (`AppGap.v4()`) and a
  horizontal (`AppGap.h4()`) form for every spacing token (`space1`…`space24`); replaces the
  hand-built `Box(style: BoxStyler().height(space4()))` spacer. The package's own
  components (`ScreenHeader`, `FactRow`, `StatusChip`, `AppListTile`) use it too.
- `AppButtonVariant.destructiveOutlined`: a page-level trigger for an irreversible action, one
  step removed from its own confirmation — outlined (`colorDanger` label, `strokeDefault`
  border, transparent fill, matching the mockups) rather than filled, so only a confirmation
  dialog's actual destructive action reads as filled. Disabled uses `colorDisabled` for both
  label and border, same pattern as `secondary`. The filled `destructive` variant is unchanged
  and still used by dialog confirm actions. Account Settings' page-level "Delete account" now
  uses it, matching the mockup (`AccountSettings-phone-dark.dc.html`'s `.btn-destructive`); the
  confirmation dialog's own "Delete" stays `destructive` (filled).

### Fixed

- Every text style in this package now resolves to the bundled Host Grotesk/IBM Plex Mono
  fonts instead of silently falling back to Flutter's default (Roboto). A font a package
  declares in its own `pubspec.yaml` `fonts:` block is only reachable, package-external, as
  `packages/ui/<family>` — `tokens.g.dart`'s `fontFamilyTitle`/`fontFamilyBody`/`fontFamilyMono`
  name the bare family instead, so every `.fontFamily(...)` call (and the two raw `TextStyle`s
  in `AppTextField`/`AppCodeField`'s input styling) needed the package prefix. Added
  `packageFontFamily()` (`src/typography/package_font_family.dart`) applied at every call site;
  `tokens/*.json` and the website's generated `tokens.g.css` are untouched, so they keep the
  plain family names their own `@font-face` resolution needs. `AppTheme` also now installs a
  `DefaultTextStyle` in the body font (size + `colorFg`), so a plain `Text` — e.g. `AppButton`'s
  label, styled only for colour via `DefaultTextStyle.merge` — renders in Host Grotesk too,
  rather than inheriting nothing from `MixScope`.
- Filled buttons and the checkbox mark now use `on-accent`, not `on-fill`. In dark mode that is
  ground-coloured text as spec §1.3 requires; white measured 2.15:1 on `danger` and 4.17:1 on
  `accent`. `on-fill` stays fixed white for the website's always-dark CTA band, and its
  token description now says so.
- `AppButton`'s label now inherits the variant's foreground colour (`on-accent` for primary and
  destructive, `fg` for secondary, `disabled` for an inert secondary). It used to fall back to
  black, which made secondary buttons invisible in dark mode and put primary labels below the
  checked contrast.

### Added

- The template's headless component library: generated design tokens
  (`lib/src/tokens.g.dart`, built by `package:tokens_builder` from `tokens/*.json`), an
  `AppTheme` widget wiring them into a `package:mix` `MixScope`, and a small set of
  accessible components built on `package:mix` + `package:naked_ui`: `Button`,
  `TextField`, `Checkbox`, `Dialog`, `Sheet`, `ListTile`.
- No `material.dart` import anywhere — every component is headless, styled only through
  mix tokens, so a clone can skin it however it wants.
- Named text styles for the app-design spec's type scale (§1.2): `displayStyle()`,
  `h1Style()`, `h2Style()`, `h3Style()`, `bodyStyle()`, `bodySmStyle()`, `captionStyle()`,
  `eyebrowStyle()`, `monoDataStyle()`, `buttonStyle()`, exposed from `src/typography/`.
- Layout primitives: `AppContentWidth`/`AppContentWrapper` (the four max-width
  presets from spec §1.1), `AppFullWidthButton`, `AppScreenScaffold` (the shared screen
  shell — header + width-capped, optionally scrollable content), and a `Breakpoint`
  re-export from `package:mix` (its built-in mobile/tablet/desktop breakpoints already
  match spec §1.1's table exactly).
- New components (`tokens-needed.md` §B): `AppScreenHeader` +
  `AppScreenHeaderBack` (back-chevron + title, replaces the per-screen hand-rolled "Back"
  button), `AppIconButton` (the icon-only tappable chrome the header's back button needs),
  `AppChevronIcon` (a headless chevron glyph, no icon-font/Material dependency),
  `AppCodeField` (a `mono-data`-styled one-time-code field with digit filtering and
  `AutofillHints.oneTimeCode` wiring), `AppStatusChip` (an `eyebrow`-styled status
  indicator), `AppCodeBlock` (a scrollable, monospace, bordered container for verbatim
  data), `AppFactRow` (a label/value definition row), `AppDivider` (a section-boundary
  hairline).

### Changed

- `AppTextField`'s and the new `AppCodeField`'s shared bordered-field styling and
  chrome-wrapping `NakedTextField.builder` are now factored into
  `internal/field_style.dart`, rather than duplicated per field.
- `AppButton`'s built-in loading spinner is now built on the shared internal `Spinner`
  widget (`internal/spinner.dart`), rather than a private copy — the new `AppLoadingIndicator`
  (below) reuses the same painter.
- Fixed: `AppContentWrapper` centered its child on *both* axes (`Center`), not
  just horizontally as its own dartdoc says, leaving a large empty band above and below any
  screen shorter than the viewport. Now `Align(topCenter)`: width still capped and centered,
  height no longer touched.

### Added

- `AppTextLinkButton`: an inline, underlined text button for a subordinate action that
  must not read as a third bordered button next to a screen's real actions — replaces a
  full `AppButtonVariant.secondary` button at every such call site (consent's "Manage in
  Settings", sign-in's "Use a different email"/legal footer links, the paywall stub's
  footer links), per spec.md §2.2/§2.3/§2.13.
- `AppLinkRow`: a centred, wrapping row of `AppTextLinkButton`s separated by middle dots —
  the legal footer on sign-in and the paywall stub.
- `AppResendButton`: a cooldown-aware resend-code affordance (spec.md §2.3) — a disabled
  countdown button while cooling down, an `AppTextLinkButton` once available again. Not
  previously modeled at all, visually or at the controller level (`tokens-needed.md` §B).
- `AppLoadingIndicator`: a standalone loading spinner for a screen region with no other
  visible content while it loads (Licences, Account Settings — spec.md §3, Pattern E: a
  `loading` model field with nothing rendered for it today).
