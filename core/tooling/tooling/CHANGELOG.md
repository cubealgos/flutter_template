# Changelog

All notable changes to `tooling` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged
`tooling-vX.Y.Z` (see `docs/releasing.md`).

## [Unreleased]

### Added

- `web_smoke` injects the vendored, checksum-pinned axe-core 4.13.0 into the booted `apps/app` web
  build and fails on any serious or critical violation; it also asserts the `flt-semantics` DOM
  exists without the old "Enable accessibility" click.

### Fixed

- `sbom` and `licence-check` no longer fail on one dropped pub.dev TLS handshake: `PubDevLicenceClient`
  reuses one keep-alive `http.Client` per run (closed at the end) and retries transient failures
  (handshake/socket/TLS errors, timeouts, 429, 5xx) with logged exponential backoff and jitter; a
  404 or other 4xx still fails at once. It also queries pub.dev's per-version score endpoint for
  the locked version (cache keyed `name@version`, old entries dropped) instead of the latest
  version's, so a just-published, not yet analysed release no longer breaks the gate; a version pub.dev has
  not analysed falls back, with a log line, to the latest version's score.
- `rename`'s leftover check exempts changelogs at any depth (basename `CHANGELOG.md`), not just
  the root one, and the tooling test fixtures use neutral example data (`example_app`) instead of
  `flutter_template`, so a fresh clone's rename exits 0.

### Removed

- `rename`'s closing note about the local Docker compose project name; the local Appwrite stack
  is gone.

### Added

- `vuln_check` command (`melos run vuln-check`, a step of the `release-artifacts` workflow): asks the
  public OSV API (no account, no new binary) about every hosted package version in the resolved
  lockfiles and fails on critical and high advisories (CVSS v3 score and OSV severity labels, highest
  wins; no readable severity counts as high) that no unexpired entry of `tool/vuln-exceptions.yaml`
  (package, advisory, reason, date, expires) covers. An expired exception fails the check; every
  active one is printed on every run.
- `RetryingHttp`, the keep-alive/retry/backoff helper extracted from `PubDevLicenceClient` so the OSV
  client shares it.

- `phrase_check` command (`melos run phrase-check`, a CI step): scans the `apps/app` i18n JSON, the
  website's copy and any `sources:` in `tool/phrase-check.yaml` for the forbidden phrases listed
  there, case-insensitively and word-aware with German forms (umlauts, ß, `*` for inflections), with
  keyed exceptions (exact sentence, reason, date) printed on every run. The template ships an empty
  list.
- `new_feature <path>` generator: scaffolds a feature's view, controller, model and mobile layout under
  `apps/app/lib/features/<path>/`, its view and layout tests, and the `TypedGoRoute` in `router.dart`
  (printing the snippet instead when the file has an unexpected shape); refuses an existing path, a
  reserved segment and non-snake_case names.
- Repo tooling for the flutter_template workspace, each exposed as a `bin/` entrypoint run
  via `fvm dart run tooling:<cmd>` or a `melos run <script>` wrapper:
  - `commit_msg` — the Conventional-Commits `commit-msg` hook rule (type + required scope
    + `(#N)`).
  - `lint_history` — re-checks commit history against the same rule, with a
    SHA-keyed grandfather list (`tool/commit-baseline.txt`).
  - `map` — generates `docs/map.md` and `docs/map/<member>.md` from every workspace
    member's public API; `map --check` fails on drift.
  - `rename` — renames every native platform field, the workspace pubspec, imports, and
    README/CLAUDE.md/docs mentions when starting a new app from this template.
  - `licence_check` — walks every hosted dependency's pub.dev-reported licence against
    the allow/deny policy and the keyed exceptions in `tool/licence-exceptions.yaml`.
  - `gen_fresh_check` — regression guard: regenerates codegen output in a fresh clone (no
    inherited build cache) and fails on drift. `gen-fresh-check.yml` seeds fvm's own
    version cache (`FVM_CACHE_PATH`) with a symlink to the job's already-fetched Flutter SDK, so
    the fresh clone's own `fvm use` finds the pinned SDK already installed instead of
    downloading it a second time — the fresh-clone semantics this check exists to guard (no
    `.dart_tool`, no build cache) are unaffected; only which Flutter SDK it links to is served
    locally instead of fetched.
  - `icons` — regenerates every platform launcher icon/splash from
    `apps/app/assets/icon/icon.png`.
  - `branch_new` / `branch_lint` — builds an issue's worktree and labels it via the GitHub
    API (`gh`); audits branch names against the six allowed families.
    `branch_lint --branch <name>` lints only that one name and reads no git refs, so CI on a
    persistent runner workspace is not failed by refs left over from earlier checkouts.
  - `finish` — plain-merges an issue's PR via `gh` (refusing on unchecked acceptance
    criteria), then verifies the check suite against merged `development` before closing
    the issue.
  - `changelog_check` — fails if a workspace member (or `mvc_lints`) lacks a
    `CHANGELOG.md`.
  - `sbom` — a CycloneDX 1.6 JSON SBOM of an app's runtime dependency closure, validated
    against the official schema in tests.
  - `licence_bundle` — `THIRD_PARTY_LICENSES` with the full licence text of every shipped
    dependency, the Flutter SDK, and bundled fonts.
  - `web_smoke` — boots the built web app (under `en-US` and `de-DE`) and the website in
    headless Chrome over the DevTools Protocol, and fails on exceptions, console errors, a
    splash that never clears, or missing localized text.
- CI runs on GitHub Actions: `.github/workflows/*.yml`, each installing the same pinned,
  sha256-verified Flutter tarball via the shared `.github/actions/setup` composite action. The
  host-cache-specific `ci_cache` (`chrome-fetch`/`pub-mark`/`build-runner-seed`/
  `build-runner-save`/`analyzer-plugin-seed`/`analyzer-plugin-save`) and `bootstrap_check`
  commands, and their drift-guard/lock/atomic-install machinery, are removed; `actions/cache`
  saves build_runner's builder-snapshot output keyed on `pubspec.lock` + `build.yaml`, with no
  janitor needed since GitHub expires unused cache entries itself. `gen-fresh-check.yml` still seeds fvm's own
  version cache from the job's already-fetched Flutter SDK (see that entry above) and stays
  genuinely cold otherwise — never fed by the build_runner cache.

### Fixed

- `rename` now also rewrites the root `NOTICE`, `CLA.md`, `CONTRIBUTING.md` and `SECURITY.md`'s
  body-text project-name mentions (e.g. CLA.md: "contributing to `flutter_template`") — their
  separate legal-identity placeholders (`core/contracts/legal_facts`' company name/address/
  emails) are left alone, for the root README's "After cloning" checklist, same as before.
  `docs/design/spec.md`/`docs/design/mockups/canvas.json` describe a dated, already-approved
  design decision for this template's own reference app and are deliberately left unrenamed
  (added to `renameLeftoverAllowList`), the same "historical, not living" reasoning as the
  generic `CHANGELOG.md` exemption.
- `finish <N>`: resumes when a prior run already merged the issue's PR but
  then failed post-merge verification (relabelling the issue `status/in-progress` instead of
  closing it) — re-running `finish <N>` used to refuse with "No open PR found for issue #N"
  forever, since the PR was already merged, leaving no way to drive the issue to closed short of
  closing it by hand. It now falls back to `gh pr list --state merged` when no open PR matches,
  and if a merged one does (and the issue isn't already closed), skips straight to re-running the
  verification suite against current `development` and closing (or relabelling) as usual, saying
  clearly in its output that it's resuming rather than merging.
- A failing verification check now prints the last 40 lines of that check's output (not just
  `Check "<name>" failed.`), and writes the full output to a log file under
  `.dart_tool/tooling/verification-<script>.log`, printing that path — previously the only
  console signal was which script failed, never which test.
- `sbom` gives every first-party workspace component (`pkg:generic/<namespace>/...`) the
  root `LICENSE` file's own SPDX id — detected from its text (currently Apache-2.0),
  falling back to no licence plus a printed warning if it can't be identified — instead of
  always omitting `licenses` outright.
- `sbom`'s purl namespace (the app's own metadata component, and every first-party
  component's purl) is now read from the workspace root pubspec's `name:` (with a trailing
  `_workspace` suffix stripped), rather than a fixed string — a clone that ran
  `tooling:rename` got its SBOM purls still branded with the template's own placeholder
  name (and would have failed `rename`'s own leftover check on this package's source, had
  it ever scanned itself).
- `licence_bundle`'s always-scanned font directories (`apps/website/web/fonts`) are now
  scanned recursively — each self-hosted font lives in its own subfolder
  (`web/fonts/host-grotesk/`, `web/fonts/ibm-plex-mono/`), which a one-level-deep scan
  missed entirely, so `licence_bundle -- --app website` previously bundled zero OFL texts.
