# Changelog

All notable changes to `legal_facts` are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); releases are tagged
`legal_facts-vX.Y.Z` (see `docs/releasing.md`).

## [Unreleased]

### Added

- `LegalFacts`: the template's single, pure-Dart, Flutter-free source for
  placeholder legal-entity facts — `companyName`, `address`, `register`, `vatId`,
  `contactEmail`, `responsiblePerson` and `supervisoryAuthority`.
- Read by both `apps/app`'s `AppConfig` (as its `legal*` field defaults) and
  `apps/website`'s Impressum/Datenschutz pages directly, so the two can never drift the
  way a duplicated `LegalPlaceholders` class did before.
- `securityEmail`: the placeholder private security-disclosure contact the
  root `SECURITY.md` quotes — kept distinct from `contactEmail` since a real clone's
  security inbox is often a different address from its general legal contact.
- Every value is an **obvious placeholder** (e.g. `companyName = 'Example GmbH'`) — a
  clone must replace every field with its own lawyer-reviewed facts before shipping; see
  also the root `NOTICE`/`CLA.md`/`SECURITY.md`, which mirror these placeholders (and the
  root `README.md`'s "After cloning" checklist for replacing them), and
  `core/tooling/tooling`'s `governance_files_test.dart`, which fails if those files drift
  from this source.
