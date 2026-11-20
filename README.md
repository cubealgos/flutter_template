# flutter_template

A Flutter monorepo template that each app clones and then owns outright.

See `CLAUDE.md` for the repo layout, toolchain and conventions; `CONTRIBUTING.md` and `CLA.md`
for how to contribute; `docs/releasing.md` for how a release is cut. Licensed under Apache-2.0
(`LICENSE`, `NOTICE`).

## After cloning

The app's identifying fields come from `core/contracts/legal_facts`
(`LegalFacts.companyName`/`.address`/`.contactEmail`/`.securityEmail`), which ship as placeholders.
The root governance files name this repository's own maintainer, Cube Algos UG. `tooling:rename`
touches none of these; replace them by hand before you rely on them:

- [ ] `core/contracts/legal_facts` itself — your own lawyer-reviewed company name, address,
      register entry, VAT ID, contact email and security email (see that package's dartdoc).
- [ ] `NOTICE`'s copyright line — your own legal entity.
- [ ] `CLA.md`'s Maintainer block — your own legal entity and address, before accepting a real
      signature.
- [ ] `SECURITY.md`'s reporting channel — your own repository's private vulnerability reporting,
      or a real, monitored address.
