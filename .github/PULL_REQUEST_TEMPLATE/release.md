<!--
Release PR: release/<pkg>-vX.Y.Z into production. See docs/releasing.md for the full flow.
Fill in every section below with a real result, not just a checked box.
-->

## Release

- Package: `<pkg>` (`<path>`)
- Version: `X.Y.Z` (tag on merge: `<pkg>-vX.Y.Z`)
- Issue: #

## Changelog

`<pkg>/CHANGELOG.md`'s `[Unreleased]` section has been moved under `## [X.Y.Z] - YYYY-MM-DD`,
with a fresh empty `[Unreleased]` left above it.

- [ ] Done

## Security gate (docs/releasing.md)

### Licence-check result

```
<paste the `fvm dart run melos run licence-check` summary line>
```

- [ ] No denied packages
- [ ] Any new exception since the last release is justified above (or: none)

### Secrets scan (gitleaks)

```
<paste the `gitleaks detect --source . --log-opts="<last-tag>..HEAD" --redact` summary>
```

- [ ] `0 leaks found`, or every finding below has been resolved (rotated/purged) and re-scanned

### Supply-chain diff

```
<paste `git diff <last-release-tag-for-this-pkg> -- pubspec.lock` (or `git log -p` for a first
release), summarised: what was added/removed/bumped and why>
```

- [ ] Reviewed

### SBOM and third-party licence bundle

- [ ] Attached (see `docs/release-artifacts.md`)
- [ ] Not yet available — release proceeds without it, explicitly noted here

## Sign-off

- [ ] The maintainer has reviewed the above and the PR diff, and approves this release explicitly (the
      structured pass above is not itself sufficient — see docs/releasing.md)

## Required status checks

Required status checks on `production` are not configured by the template — until a clone enables them,
every gate in `CONTRIBUTING.md`'s validation-gate table still runs on this PR, it just isn't yet
a merge-blocking branch-protection rule. This sign-off is what stops an unreviewed release from
merging in the meantime.
