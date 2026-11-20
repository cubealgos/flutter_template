# website

The template's landing page — a [Jaspr](https://jaspr.site) **static** site,
cloned alongside `apps/app`. See the root `CLAUDE.md` for the workspace's melos scripts,
branch/issue workflow and lint rules.

## What's here

- `lib/app.dart` — the route table (a plain `switch` on the request path, not
  `package:jaspr_router` — see that file's own doc comment for why: every published
  jaspr_router version needs a jaspr API this workspace's pinned `jaspr: 0.23.1` doesn't
  have yet).
- `lib/src/pages/` — `HomePage`, `ImpressumPage`, `DatenschutzPage`, `NotFoundPage`, each
  built for both locales (`SiteLocale.en`/`.de`).
- `lib/src/components/` — `Hero`, `FeatureGrid`, `StatsSection`, `CtaSection`,
  `SiteNav`, `SiteFooter`.
- `lib/src/i18n/site_strings.dart` — every page's copy, hand-written en/de (no slang/ARB —
  the surface is small; see that file's own doc comment).
- Impressum/Datenschutz legal facts come from `package:legal_facts` (`core/contracts/
  legal_facts`) — the same pure-Dart source `apps/app/lib/app/config.dart`'s
  `AppConfig` defaults its `legal*` fields from, so the two can never drift; checked by
  `test/legal_pages_test.dart`.
- `web/tokens.g.css` — **generated**, never hand-edited. Built from
  `core/design/ui/tokens/*.json` by `core/design/tokens_builder`'s CSS emitter
  (`melos run gen`'s `gen:website-tokens` step) — the same design-token source
  `core/design/ui/lib/src/tokens.g.dart` is built from, light default + dark via
  `prefers-color-scheme`.
- `web/site.css` — hand-authored layout/component CSS, entirely in terms of
  `tokens.g.css`'s custom properties. Square corners throughout (no chamfer/clip-path).
- `web/motion.js` — scroll-reveal + count-up, a plain static script (not a Jaspr
  `@client` component — see its own doc comment for why), active only under
  `prefers-reduced-motion: no-preference`.

## Commands

```
fvm dart run melos run website:build   # static build -> build/jaspr/ (gitignored)
fvm dart run melos run website:serve   # dev server with hot reload
```

`website:build` invokes `jaspr_cli` via `dart run jaspr_cli:jaspr build` — never a global
`dart pub global activate`, per the workspace's Dart-only-tooling rule.

## Versions

Pinned to the Jaspr **0.23.1** set (`jaspr`, `jaspr_builder`, `jaspr_cli`, `jaspr_test`) —
the last release whose `jaspr_builder`/`jaspr_cli` still depend on `analyzer ^10.0.0`; 0.23.2+
needs `analyzer ^12.1.0`, which conflicts with this workspace's analyzer 10.x-13.x pin
(`packages/domain`'s freezed 3.2.5 needs analyzer <11). See `pubspec.yaml`'s own comments for
the full chain, including why there is no `jaspr_router` dependency.

## Renaming

`fvm dart run tooling:rename` (see the root `CLAUDE.md`) rewrites this site's
`lib/src/site_constants.dart` `productName` placeholder to the new app's display name —
every page's `<title>`/nav/footer copy interpolates that one constant, so nothing else here
needs touching.
