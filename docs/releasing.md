# Releasing

Releases here are driven by GitHub issues and `tooling:finish`, with per-package tags rather
than a single repo-wide version. Read the root `CLAUDE.md`
first (branches, worktrees, commit conventions) — this file only covers the release-specific
parts.

## Per-package versioning, from day one

Every workspace member, plus `core/architecture/mvc_lints` (independently tagged despite not
being a workspace member — see its `pubspec.yaml`), is its own release unit: its own SemVer, its
own tag prefix, its own `CHANGELOG.md` (Keep a Changelog, `[Unreleased]` kept current as changes
land — see `melos run changelog-check`, which fails a PR that adds a package with no
`CHANGELOG.md`). A change to one package does not imply a release of any other.

| Package | Path | Tag prefix |
| --- | --- | --- |
| `app` | `apps/app` | `app-v` |
| `website` | `apps/website` | `website-v` |
| `mvc` | `core/architecture/mvc` | `mvc-v` |
| `mvc_lints` | `core/architecture/mvc_lints` | `mvc_lints-v` |
| `tooling` | `core/tooling/tooling` | `tooling-v` |
| `domain` | `packages/domain` | `domain-v` |
| `appwrite_schema` | `backend/appwrite/schema` | `appwrite_schema-v` |
| `tokens_builder` | `core/design/tokens_builder` | `tokens_builder-v` |
| `ui` | `core/design/ui` | `ui-v` |
| `auth` | `core/contracts/auth` | `auth-v` |
| `data` | `core/contracts/data` | `data-v` |
| `teams` | `core/contracts/teams` | `teams-v` |
| `legal_facts` | `core/contracts/legal_facts` | `legal_facts-v` |
| `appwrite_adapters` | `backend/appwrite/adapters` | `appwrite_adapters-v` |
| `appwrite_tool` | `backend/appwrite/tool` | `appwrite_tool-v` |
| `api` | `backend/appwrite/functions/api` | `api-v` |

A tag is `<prefix>X.Y.Z`, e.g. `app-v1.2.0` or `mvc_lints-v0.3.1`. No package has cut a real
release yet — every `CHANGELOG.md` in this repo today is still `[Unreleased]`.

## The flow

1. **`release/<pkg>-vX.Y.Z` branches from `development`**, in its own worktree
   (`tooling:branch_new release <N> <pkg>-vX.Y.Z`, `N` = the release's own GitHub issue —
   "no work without a ticket" has no release exception).
2. **Move the package's `CHANGELOG.md` `[Unreleased]` section under `## [X.Y.Z] - YYYY-MM-DD`**,
   leaving a fresh empty `[Unreleased]` above it.
3. **Run the security gate** (below) on the release branch and write its findings and verdict
   into the release PR body, using the checklist template at
   `.github/PULL_REQUEST_TEMPLATE/release.md`.
4. **Open the PR** from `release/<pkg>-vX.Y.Z` into `production`. A bug found while gating: fix
   it on the release branch via its own issue if small; if structural, abort the release (delete
   the branch, fix on `development`, re-cut).
5. **Human sign-off**: the maintainer approves the security-gate verdict explicitly, in the PR, before
   merge — the gate is a structured pass *plus* human approval, never the pass alone.
6. **Merge (plain merge commit, never squash/rebase) into `production`.**
7. **Tag `production` at the merge commit** with `<pkg>-vX.Y.Z`.
8. **Back-merge `production` into `development`** so the changelog move and any release-branch
   fix land there too.

### Hotfixes

`hotfix/<pkg>-vX.Y.Z` branches from `production`, same security gate, same PR review, merges to
**both** `production` (tag there) **and back into `development`**. A patch bump. Still needs its
own GitHub issue first — there is no 2 a.m. exception to "no work without a ticket".

### Required status checks

**Every gate in `CONTRIBUTING.md`'s validation-gate table already runs on every PR and every push
to `development`/`production` today** (GitHub Actions on GitHub-hosted runners, under `.github/workflows/`). What does **not** exist is
a branch-protection rule that makes any of them *required* before a merge is offered: the
template does not configure one (a clone enables branch protection itself). Until then, the
security gate's human sign-off, and `tooling:finish`'s re-verification on merged `development`,
are what actually stop an unreviewed or broken release from merging.

## Deploying

Deployment is a separate act from verification: **no CI workflow deploys** (CI only
verifies, see "Required status checks"), and a failed deploy is a **new issue**, never a red
check. An operator deploys from a checkout with `backend/appwrite/tool`'s commands; the dev
project uses `backend/appwrite/tool/.env.local`, production its own gitignored
`.env.production.local`. Production is reached only with the explicit `--production` flag;
without it every command refuses (see `backend/appwrite/README.md`, "Sites, production and
promotion", for how and for the scoped API keys).

Promote a release to production, from the main checkout (not a worktree), run in
`backend/appwrite/tool/`:

1. Check out the release tag: `git checkout <pkg>-vX.Y.Z` (tree must be clean).
2. Build both web outputs from the repo root; the tool never builds:
   `(cd apps/app && fvm flutter build web --dart-define=BACKEND=appwrite --no-web-resources-cdn)`
   and `fvm dart run melos run website:build`.
3. Dry run: `fvm dart run bin/promote.dart --production --dry-run` — reports the schema
   changes it would make and checks every Function and both Site builds, sending no writes.
4. Real run: `fvm dart run bin/promote.dart --production` — it refuses without the dry run of
   the same commit. Order: schema, Functions (`api`), Sites
   (`app`, `website`); it stops at the first failure.
5. Check the deployed Sites in a browser, then `git checkout development`.

Single pieces: `bin/provision.dart`, `bin/deploy.dart <function-id>` and
`bin/deploy_site.dart <site-id>` all take `--production`; `provision.dart` and
`deploy_site.dart` also take `--dry-run` (`deploy.dart` has none).

## Security-gate checklist

The checklist below is what `.github/PULL_REQUEST_TEMPLATE/release.md` asks a release PR to fill
in. Every item needs an actual result pasted in, not a checked box with nothing behind it.

- **Licence-check result.** Run `fvm dart run melos run licence-check` on the release branch and
  paste its summary line (`N package(s) checked — N allowed, N exempted, N verified, N
  denied`). Any denied package blocks the release; any *new* exception since the last release
  needs its own one-line justification in the PR body (same discipline as the
  licence policy in `licence_policy.dart`).
- **Secrets scan.** This workspace has no Dart-native secrets scanner; **gitleaks** (Go, MIT —
  already on the dependency-license allow list, and since it's a standalone binary rather than a
  pub package it never enters this workspace's own dependency graph or `pubspec.lock` at all) is
  the concrete tool: it scans git history and the working tree for credential-shaped patterns
  and high-entropy strings, works on any language, and needs no project-specific config to be
  useful as a release-time check. Run it from the release worktree:
  ```
  gitleaks detect --source . --log-opts="<last-release-tag-for-this-pkg>..HEAD" --redact
  ```
  (first release for a package with no prior tag: `gitleaks detect --source . --redact` over the
  whole history once, then scope subsequent releases to the range above). Paste the summary
  (leak count; `0 leaks found` for a clean pass) into the PR. A finding blocks the release until
  resolved (rotate the credential, purge it from history, re-scan) — never silenced by narrowing
  the scan.
- **Supply-chain diff.** `git diff <last-release-tag-for-this-pkg> -- pubspec.lock` (or, for a
  package with no prior tag, `git log -p -- pubspec.lock` since it entered the workspace) —
  paste which dependencies were added, removed or bumped since the last release of *this*
  package. Anything new should already have cleared `licence-check`; this diff is about
  reviewing *what* changed and *why*, not re-running the licence gate.
- **SBOM and third-party licence bundle.** Documented in `docs/release-artifacts.md` — referenced here. Its SBOM/licence-bundle output is attached to
  the release PR as an additional checklist item; until then this line stays unchecked and the
  release PR says so explicitly rather than silently omitting it.
- **Human sign-off.** The maintainer reviews the above and the PR's actual diff, then approves the PR
  explicitly. The merge does not happen on the structured pass alone.
