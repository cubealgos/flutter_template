# Changelog

All notable changes to `website` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged
`website-vX.Y.Z` (see `docs/releasing.md`).

## [Unreleased]

### Changed

- `jaspr: port: 8091` instead of jaspr's default 8080, which commonly clashes with other local
  services; it is the pre-render server of `jaspr build` and the
  port of `jaspr serve`.

### Added

- The template's landing page: a [Jaspr](https://jaspr.site) **static** site
  (`jaspr: mode: static`), cloned alongside `apps/app`, no Flutter dependency.
- A plain-`switch` route table (`lib/app.dart`) covering `HomePage`, `ImpressumPage`,
  `DatenschutzPage` and `NotFoundPage`, each built for both `en` and `de` locales, with
  hand-written copy under `lib/src/i18n/site_strings.dart`.
- Components: `Hero`, `FeatureGrid`, `StatsSection`, `CtaSection`, `SiteNav`, `SiteFooter`.
- Impressum/Datenschutz pages read `package:legal_facts` directly — the same placeholder
  source `apps/app`'s `AppConfig` defaults its `legal*` fields from, so the two can never
  drift.
- Styling generated from `core/design/ui/tokens/*.json` into plain CSS custom properties
  (`web/tokens.g.css`, via `melos run gen`'s `gen:website-tokens` step; light default,
  dark via `prefers-color-scheme`), plus hand-authored `web/site.css` and a
  `prefers-reduced-motion`-gated `web/motion.js` scroll-reveal/count-up script.
- `fvm dart run melos run website:build` / `website:serve` for a static build and a hot-
  reload dev server.
- Neutral placeholder copy, replaced with real content after cloning (see
  `tooling:rename`, which rewrites `lib/src/site_constants.dart`'s `productName`).
- Landing page rebuilt for visual parity with the reference site (the original port didn't
  match its style, sections or copy structure):
  - `Hero` is now two-column: the content block plus a decorative motif (three layered,
    outlined squares) and a "Plan → Build → Ship" `ProcessSection` diagram with its own
    scroll-drawn connector line at ≥1024px.
  - `FeatureGrid` is a reusable bento-grid (title/description, optional link, hero/wide/
    normal spans), rendered twice ("what you get", "what we build"); `ProofSection`
    replaces `StatsSection` with a status badge, a count-up stat, a plain stat and tag
    pills; `FaqSection` ports the reference site's WAAPI-animated, progressively-enhanced
    `<details>`/`<summary>` disclosures.
  - `SiteNav` gains a mobile hamburger/overlay pattern below 1024px (`aria-expanded`,
    Escape closes, focus returns to the toggle) carrying the language switcher and CTA
    that no longer fit inline at narrow widths; `SiteFooter` gains its own bottom-row
    language switcher.
  - No-JS fallback: a `<noscript>` override keeps `[data-reveal]` content visible without
    JavaScript (the reveal class is JS-applied), and `ProofSection`'s animated stat
    server-renders its real final value instead of a literal `0` that only JavaScript
    would ever replace.
  - Host Grotesk and IBM Plex Mono (SIL OFL-1.1, from the google/fonts GitHub repo) are
    self-hosted rather than loaded from a CDN: `.woff2` under `web/fonts/<font>/` for the
    website, the original `.ttf` under `core/design/ui/assets/fonts/` for the Flutter app;
    each font's own `OFL.txt` ships alongside it, and `tool/font-licences.md` records the
    licence decision and provenance (`licence_check` only walks pub packages, so font
    assets are out of its scope by design).
