# Vendored axe-core 4.13.0

`axe.min.js` is the unmodified `axe.min.js` from the npm package `axe-core@4.13.0`
(<https://registry.npmjs.org/axe-core/-/axe-core-4.13.0.tgz>), licensed MPL-2.0 (`LICENSE`).
It is a test-time asset only: `tooling:web_smoke` injects it into the booted web build in
headless Chromium (#56). It is never bundled into an app or the website, so it is not in a
release SBOM or licence bundle; the MPL-2.0 exception is recorded in `tool/licence-exceptions.yaml`.

The file is vendored rather than fetched so the check needs no network and cannot be broken or
tampered with upstream. `web_smoke` refuses to run it unless its SHA-256 equals
`axeSha256` in `lib/src/web_smoke_axe.dart` (`c24f097b...a0c1`).

To bump: download the new tarball, replace `axe.min.js` and `LICENSE`, update the version here
and the checksum in `web_smoke_axe.dart`, and re-run `melos run web-smoke`.
