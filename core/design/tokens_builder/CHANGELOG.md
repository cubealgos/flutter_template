# Changelog

All notable changes to `tokens_builder` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged
`tokens_builder-vX.Y.Z` (see `docs/releasing.md`).

## [Unreleased]

### Added

- The DTCG `number` token type, for unitless values such as line heights and scale factors: the CSS emitter writes a bare number (`--line-height-body: 1.5;`, never `1.5px`) and the Dart emitter a `double` (a `DoubleToken` with the value `1.5`, a whole `2` as `2.0`). A `$value` that is not a JSON number, a numeric string included, is a build error naming the token, and an unknown `$type` still fails. Brand token sets that wrote these values as strings (the puffrr_branding stopgap) can go back to `number`.
- A `build_runner` `Builder` (`tokensBuilder`) that turns DTCG design-token JSON
  (`core/design/ui/tokens/*.json`) into `package:mix` token declarations
  (`core/design/ui/lib/src/tokens.g.dart`) — depends only on `package:build`, never
  `package:analyzer`/`source_gen`, so it can't move the workspace's analyzer pin.
- A standalone CSS emitter bin (`bin/build_css.dart`) that reads the same token source
  and writes `apps/website/web/tokens.g.css` as plain custom properties (light default,
  dark via `prefers-color-scheme`) — a plain bin rather than a Builder, since a Builder
  can only read/write inside its own package.
- Explicit handling for every DTCG dimension unit, rather than an assumed
  rem/px transform.
