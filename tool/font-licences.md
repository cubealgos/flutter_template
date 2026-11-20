# Font licences

`melos run licence-check` (`core/tooling/tooling`'s `licence_check`) walks every `source: hosted`
package in `pubspec.lock` against the allow/deny policy in
`core/tooling/tooling/lib/src/licence_policy.dart` — it has no notion of a font asset, so the two font families this template ships are **out
of that gate's scope** and are recorded here instead (decision of 2026-09-25).

## Fonts shipped

| Family | Source | Licence | Used by |
| --- | --- | --- | --- |
| Host Grotesk (variable, wght 300–800) | `google/fonts` GitHub repo, `ofl/hostgrotesk/HostGrotesk[wght].ttf` | SIL Open Font License, Version 1.1 | `apps/website` (`@font-face`, woff2) and `core/design/ui` (Flutter `fonts:`) — headings and body |
| IBM Plex Mono (static, weight 400) | `google/fonts` GitHub repo, `ofl/ibmplexmono/IBMPlexMono-Regular.ttf` | SIL Open Font License, Version 1.1 | `apps/website` (`@font-face`, woff2) and `core/design/ui` (Flutter `fonts:`) — eyebrows, data, labels |

**OFL-1.1 is allowed for font assets** in this workspace (decision of 2026-09-25) — it is not
on the pub-package allow list in `licence_policy.dart` (that list is scoped to code
dependencies), but the SIL Open Font License is a standard, permissive font licence with no
copyleft effect on the software that embeds the font; both families ship it verbatim.

## Provenance

Both `.ttf` source files were fetched directly from the upstream `google/fonts` GitHub repository
(`ofl/hostgrotesk/`, `ofl/ibmplexmono/`) — never from `fonts.googleapis.com`/`fonts.gstatic.com` at
runtime, and never from any other CDN. `fonttools`' own `ttLib.woff2` compressor converted each
`.ttf` to `.woff2` for the website (Flutter's `fonts:` block takes the `.ttf` directly). Every
directory that ships a font file ships that font's own unmodified `OFL.txt` immediately next to it:

- `apps/website/web/fonts/host-grotesk/{HostGrotesk-wght.woff2, OFL.txt}`
- `apps/website/web/fonts/ibm-plex-mono/{IBMPlexMono-Regular.woff2, OFL.txt}`
- `core/design/ui/assets/fonts/host-grotesk/{HostGrotesk-wght.ttf, OFL.txt}`
- `core/design/ui/assets/fonts/ibm-plex-mono/{IBMPlexMono-Regular.ttf, OFL.txt}`

Both are self-hosted: the website serves them from its own origin via `@font-face` /
`font-display: swap` (`apps/website/web/site.css`), and the Flutter app bundles them as assets via
`core/design/ui/pubspec.yaml`'s `flutter: fonts:` block. Neither ships from a CDN at runtime.
