# CI runner prerequisites

Every workflow in `.github/workflows/` runs on a **GitHub-hosted** `ubuntu-24.04` runner
(one literal `runs-on:` value, repeated per file, so a provider swap is a one-line change per
file). No job uses a self-hosted runner, containers, `services:` or `docker` actions, and no
workflow reads a repository or organisation secret: everything a fork needs is the public
`GITHUB_TOKEN` that `actions/checkout` uses.

## What the workflows install

- `.github/actions/setup` installs the pinned, sha256-verified Flutter SDK (which bundles Dart)
  into `$RUNNER_TOOL_CACHE`, points PATH and melos at it and runs `dart pub get`. It also
  verifies that `git`, `curl`, `tar`, `xz`, `sha256sum` and `flock` exist and that git is
  **>= 2.48** (`git worktree add --relative-paths`, used by `core/tooling/tooling` and its
  tests); the `ubuntu-24.04` image provides all of them.
- `build-linux` installs the Linux desktop toolchain with `apt-get`: `clang cmake ninja-build
  pkg-config libgtk-3-dev liblzma-dev libstdc++-14-dev`, the plugin build dependencies
  `libwebkit2gtk-4.1-dev libsoup-3.0-dev` (`desktop_webview_window`, via `appwrite` ->
  `flutter_web_auth_2`) and `ccache`.
- `web-smoke` installs the runtime libraries Chrome for Testing needs (the list it ships in its
  own `chrome-linux64/deb.deps`) and fetches the pinned, sha256-verified Chrome for Testing
  build itself.
- `gen-fresh-check` activates `fvm` with `dart pub global activate fvm`.
- Bumping a pin (Flutter, Chrome for Testing) is a change to the workflow or action file that
  carries it.

## Network egress

`github.com`, `storage.googleapis.com` (Flutter SDK, Chrome for Testing), `pub.dev` and
`pub.dartlang.org` (packages, score API for `licence-check`), and `api.osv.dev` (advisories for
`vuln-check`). All are public endpoints.

## Caching

Hosted runners start clean, so the Flutter SDK and Chrome for Testing are downloaded on every
run; `actions/cache` is used only for the `build_runner` snapshots (`ci`, `web-smoke`). A fork
that wants faster runs can add a cache for `$RUNNER_TOOL_CACHE` and `~/.pub-cache`.
