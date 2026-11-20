# Contributing

`flutter_template` is developed with GitHub issues — see the root
`CLAUDE.md` for the full branch/issue workflow and `docs/releasing.md` for how a release is cut.
This file covers how the team (and any outside contributor) works day to day.

## How this team works

- **Branching model: two long-lived branches.** `production` (releasable) and `development`
  (integration, default). Neither is ever committed to directly.
- **Six branch families, exactly:** `feature/`, `bugfix/`, `chore/`, `documentation/`,
  `release/` (from `development`) and `hotfix/` (from `production`), named
  `family/N-slug` where `N` is the GitHub issue number (for example
  `chore/51-release-governance`). `tooling:branch_new <family> <N> <slug>` builds the worktree
  and labels the issue. Every working branch gets its own worktree under `.worktrees/`;
  **`git stash` is forbidden** — use a worktree or a WIP commit instead.
- **Commits follow Conventional Commits** with a required type and scope:
  `type(scope): description (#N)`, type one of `feat fix docs style refactor perf test build ci
  chore revert merge release`. Enforced locally by `tool/hooks/commit-msg` (`melos run hooks`
  installs it) and re-checked over history by `fvm dart run tooling:lint_history`.
- **One issue, one branch, one PR.** A bug found while working an issue gets its own issue and
  its own `bugfix/*` branch — the current branch never absorbs unrelated fixes.
- **`tooling:finish <N>`** plain-merges the PR (refusing on unchecked acceptance criteria), then
  verifies the check suite against merged `development` before closing the issue.

## Validation gates

Every gate below runs via `fvm dart run melos run <script>` and is wired into
`.github/workflows/*.yml` (the quick gates are steps of the one `ci` job, the heavier ones their own
workflow, verification only — see the root CLAUDE.md). Every gate runs on every PR and on every push
to `development`/`production`. `check-generated` is not a CI step (`gen-fresh-check` covers it; the
script still runs locally), and `docs-check` is its own workflow so it runs in parallel with `ci`.
**None is a merge-blocking required check:**
The template configures no branch protection, so `tooling:finish` is what refuses to
merge a PR with unchecked criteria and re-verifies on merged `development` before closing.

| What it checks | Command |
| --- | --- |
| Formatting | `melos run format` |
| Static analysis (`very_good_analysis` + `solid_lints` + `mvc_lints`) | `melos run analyze` |
| Tests (`flutter test` / `dart test`) | `melos run test` |
| Generated code is committed and current | `melos run gen-fresh-check` in CI; `melos run check-generated` locally |
| `docs/map.md` is current | `melos run map-check` |
| Every workspace member (+ `mvc_lints`) has a `CHANGELOG.md` | `melos run changelog-check` |
| Dependency licences (allow/deny list) | `melos run licence-check` |
| Dartdoc resolves and every public member is documented | `melos run docs-check` (own workflow) |
| Branch names conform | `fvm dart run tooling:branch_lint` |
| Commit history conforms | `fvm dart run tooling:lint_history` |

**If a gate fails: fix the source of truth, don't widen the check to pass.** A gate that was
loosened to get a PR through stops meaning what it says.

## Contributing (external)

Thanks for wanting to contribute.

### Before you start

- **Sign the CLA** — required before a first PR is merged, see `CLA.md`. This keeps the project
  genuinely open while preserving the Maintainer's ability to relicense or offer a commercial or
  hosted edition — Apache-2.0 + CLA is this template's own standing licence default.
- **Open an issue first** for anything non-trivial (new feature, behaviour change). Small fixes
  and docs can go straight to a PR.
- **Work on a branch, in its own worktree** — never commit directly to `development` or
  `production`.
- **Keep the scope tight.** One PR, one concern.

### Commit and PR conventions

Commit messages follow Conventional Commits as described above, including the scope and the
issue reference. A good PR has a clear title (a conforming commit subject ending `(#N)` — the
merge template makes it the merge-commit subject), says *what* changed and *why*, states how it
was tested (which gates were run), and carries the issue's acceptance-criteria checklist in its
body.

### Security

Do not report a suspected vulnerability in a public issue or PR — see `SECURITY.md` for the
private disclosure path.

## Licence-related pubspec fields

Every workspace member's `pubspec.yaml` carries `publish_to: none` (none are published to
pub.dev) and no per-package `license:` metadata — pub's package format has no such key; the
root `LICENSE`/`NOTICE` govern the whole repo, same as any other monorepo of unpublished
packages under one licence. This is consistent across every member; a clone that later
publishes an individual package to pub.dev adds that package's own `LICENSE` at that point.
