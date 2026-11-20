import 'dart:io';

import 'package:path/path.dart' as p;

/// Recognises the root `LICENSE` file's own SPDX identifier from its
/// text, for `tooling:sbom`'s first-party workspace components
/// (`sbom_command.dart`'s `_firstPartyComponent`) — every workspace
/// member under `core/`/`backend/`/`packages/`/`apps/` is covered by this
/// one repo-root licence, never its own separate `LICENSE` file, so
/// there's exactly one file to read and classify.
///
/// Recognises Apache-2.0 by the exact header every official Apache-2.0
/// `LICENSE` file opens with ("Apache License" immediately followed by
/// "Version 2.0") — this template's own default (see CLAUDE.md's "Licence
/// and release boundaries" section) — and returns `null` for anything
/// else (an unrecognised licence text, or a clone that swapped its root
/// `LICENSE` for something this function doesn't know) rather than
/// guessing. Never throws.
String? detectRootLicenceSpdxId(String licenceText) {
  final apacheHeader = RegExp(r'Apache License\s*\r?\n\s*Version 2\.0');

  return apacheHeader.hasMatch(licenceText) ? 'Apache-2.0' : null;
}

/// Reads `<repoRoot>/LICENSE` and returns [detectRootLicenceSpdxId]'s
/// verdict on it, or `null` if the file doesn't exist at all — an
/// unexpected clone state (CLAUDE.md's licence-and-release-boundaries
/// section assumes a root `LICENSE` exists), but not this reader's job to
/// enforce; the caller (`sbom_command.dart`) decides how loudly to warn.
String? readRootLicenceSpdxId(String repoRoot) {
  final file = File(p.join(repoRoot, 'LICENSE'));
  if (!file.existsSync()) return null;

  return detectRootLicenceSpdxId(file.readAsStringSync());
}
