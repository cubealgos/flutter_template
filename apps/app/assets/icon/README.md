# App icon source

Source-of-truth images `dart run melos run icons` (`core/tooling/tooling`'s `icons` command) reads to
regenerate every platform launcher icon, favicon and splash screen. Never hand-edit a generated
output (Android `mipmap-*`, iOS `AppIcon.appiconset`, `web/icons/*`, `web/favicon.ico`, `linux/
runner/resources/app_icon.png`, …) — replace the source here and re-run the command instead.

Placed under `apps/app/` (not the repo root) because this template is cloned per app: an app that
drifts from the template after cloning should still find its own icon source next to its own
`pubspec.yaml`, `web/`, `linux/`, not reach up past `apps/app/` into a workspace-root directory
that a multi-app fork would have to share or duplicate.

## Files

| file | size | alpha | purpose |
| --- | --- | --- | --- |
| `icon.png` | 1024×1024 | **no** (opaque) | Base icon: Android legacy/adaptive background composite, iOS, macOS, Windows, web favicon/PWA icons. No alpha — iOS and the generated `favicon.ico` both reject a transparent background. |
| `icon_foreground.png` | 1024×1024 | yes (transparent) | Android adaptive-icon foreground layer, composited over `adaptive_icon_background`. Also reused as the native-splash image (transparent background lets the splash screen's own solid colour show through). |
| `icon_monochrome.png` | 1024×1024 | yes (transparent) | Android 13+ themed-icon layer (Material You). System re-tints this layer to a single colour at runtime, so only the alpha shape matters — colour information outside alpha is ignored. |

## Requirements for a replacement

- **1024×1024 PNG**, square, no rounded corners or drop shadow baked in — every platform applies
  its own mask/shape.
- **Safe zone**: `icon_foreground.png` and `icon_monochrome.png` must keep the mark inside a
  centered **66%-diameter circle** (Android's adaptive-icon safe zone, a 66dp circle inside a
  108dp canvas) — content outside it is clipped by circular/squircle/rounded-square launcher
  masks. This repo's placeholder keeps the mark at 55% diameter for a visible margin inside that
  zone.
- **Transparency**: `icon.png` must have **no alpha channel** (fully opaque) or an opaque
  background baked in at export. `icon_foreground.png`/`icon_monochrome.png` must be transparent
  outside the mark.
- **`icon_monochrome.png`** should be a single flat colour (white recommended) on transparent —
  Android discards colour and keeps only the alpha shape.

## Current placeholder

Generated programmatically (not hand-drawn, no brand, no text): a plain white circle centered on
`core/design/ui/tokens/color.light.json`'s `color.accent` (`#1d6fe0`) for `icon.png`, and the same
circle on transparent for the foreground/monochrome variants, at 55% diameter. Replace all three
before shipping a real app.
