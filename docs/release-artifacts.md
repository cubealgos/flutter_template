# Release artifacts: SBOM and third-party licence bundle

Two obligations this template's own release process owes from the first real release:

- **A CycloneDX SBOM per release** — the EU Cyber Resilience Act's practical lever:
  the thing that makes "do we ship the affected component, and in which released versions?"
  answerable at all once Article 14's 24-hour reporting clock is running.
- **A third-party licence bundle** — reproducing each dependency's own licence text in the
  redistributed artifact, a separate obligation from any upstream `NOTICE` requirement, owed the
  moment a compiled artifact ships (a separate obligation under MIT/BSD-style licences).

Both tools operate on one app's own resolved **runtime dependency closure** (derived from
`dart pub deps --json`, not the whole workspace's flat `pubspec.lock`) — first-party workspace
members included as their own components, third-party packages resolved from pub.dev and the
Flutter SDK.

## Running them

```sh
dart run melos run sbom              # apps/app -> build/release/app/sbom.cdx.json
dart run melos run sbom -- --app website
dart run melos run licence-bundle    # apps/app -> build/release/app/THIRD_PARTY_LICENSES
dart run melos run licence-bundle -- --app website
```

`build/release/` is gitignored (already covered by the workspace-wide `build/` entry) — these are
generated release artifacts, never committed.

Only `apps/app` (the Flutter web build) and `apps/website` (the Jaspr static site) are covered:
web is the only platform this template verifies before release (decision of 2026-09-25).

## Implementation

`core/tooling/tooling`'s `sbom`/`licence_bundle` commands (`lib/src/sbom_command.dart`,
`lib/src/licence_bundle_command.dart`) reuse `licence_check`'s own lockfile parsing, pub.dev
licence client and `tool/licence-exceptions.yaml` `verified:` overrides — the SBOM documents
"what licence did we find", never `licence_check`'s allow/deny verdict. The licence bundle fails
loudly (non-zero exit) if any hosted package's LICENSE text can't be found on disk, or if the
Flutter SDK's own `LICENSE` is missing.

## CI gate

`.github/workflows/release-artifacts.yml` runs both tools for both apps on every PR and every push to `development`/`production`, and fails
the build if either tool itself fails — verification only, no publishing, same as every other
`.github/workflows/*.yml` file. This is the release checklist's gate to point at; the release process
itself (when to cut a release, how `build/release/`'s output actually ships with the built
artifact) is covered in `docs/releasing.md`, not here.
