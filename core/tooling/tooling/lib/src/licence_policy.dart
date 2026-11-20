/// The dependency-licence allow/deny policy: this file is the source of
/// truth for `melos run licence-check`.
library;

/// Canonical (policy-document-cased) SPDX identifiers this workspace
/// accepts unconditionally.
const Set<String> allowedLicences = <String>{
  'MIT',
  'Apache-2.0',
  'Apache-2.0 WITH LLVM-exception',
  'BSD-2-Clause',
  'BSD-3-Clause',
  'Unicode-3.0',
  'Unlicense',
  'CC0-1.0',
  'Zlib',
  'ISC',
  'PSF-2.0',
  'BlueOak-1.0.0',
  'MIT-0',
  '0BSD',
};

/// Canonical SPDX identifiers this workspace refuses outright — no
/// exceptions mechanism reaches these (unlike MPL-2.0 below).
const Set<String> deniedLicences = <String>{
  'GPL-1.0-only',
  'GPL-1.0-or-later',
  'GPL-2.0-only',
  'GPL-2.0-or-later',
  'GPL-3.0-only',
  'GPL-3.0-or-later',
  'AGPL-1.0-only',
  'AGPL-1.0-or-later',
  'AGPL-3.0-only',
  'AGPL-3.0-or-later',
  'LGPL-2.0-only',
  'LGPL-2.0-or-later',
  'LGPL-2.1-only',
  'LGPL-2.1-or-later',
  'LGPL-3.0-only',
  'LGPL-3.0-or-later',
  'SSPL-1.0',
  'BUSL-1.1',
};

/// MPL-2.0: deny by default, allow only via a keyed exception in
/// `tool/licence-exceptions.yaml` — see the policy document's "MPL-2.0:
/// deny by default, not silently allowed" section. Not in [allowedLicences]
/// or [deniedLicences]; `LicenceCheckCommand` special-cases it.
const String mplLicence = 'MPL-2.0';

/// Maps a pub.dev `license:<tag>` suffix (lower-case, hyphenated — see
/// `GET https://pub.dev/api/packages/<name>/score`'s `tags` array) to the
/// canonical SPDX identifier this policy is written in terms of. Pub.dev
/// also emits two non-licence badge tags sharing the `license:` prefix,
/// `fsf-libre` and `osi-approved`, plus `unknown` when no licence was
/// detected — none of those are licence identifiers and are filtered out
/// by `PackageLicences.spdxCandidates` before this map is consulted.
///
/// `python-2.0` is aliased to `PSF-2.0` per the policy document's explicit
/// call ("SPDX `Python-2.0` is read as PSF-2.0").
const Map<String, String> pubDevTagToSpdx = <String, String>{
  'mit': 'MIT',
  'apache-2.0': 'Apache-2.0',
  'apache-2.0-with-llvm-exception': 'Apache-2.0 WITH LLVM-exception',
  'bsd-2-clause': 'BSD-2-Clause',
  'bsd-3-clause': 'BSD-3-Clause',
  'unicode-3.0': 'Unicode-3.0',
  'unlicense': 'Unlicense',
  'cc0-1.0': 'CC0-1.0',
  'zlib': 'Zlib',
  'isc': 'ISC',
  'psf-2.0': 'PSF-2.0',
  'python-2.0': 'PSF-2.0',
  'blueoak-1.0.0': 'BlueOak-1.0.0',
  'mit-0': 'MIT-0',
  '0bsd': '0BSD',
  'mpl-2.0': mplLicence,
  'gpl-1.0-only': 'GPL-1.0-only',
  'gpl-1.0-or-later': 'GPL-1.0-or-later',
  'gpl-2.0-only': 'GPL-2.0-only',
  'gpl-2.0-or-later': 'GPL-2.0-or-later',
  'gpl-3.0-only': 'GPL-3.0-only',
  'gpl-3.0-or-later': 'GPL-3.0-or-later',
  'agpl-1.0-only': 'AGPL-1.0-only',
  'agpl-1.0-or-later': 'AGPL-1.0-or-later',
  'agpl-3.0-only': 'AGPL-3.0-only',
  'agpl-3.0-or-later': 'AGPL-3.0-or-later',
  'lgpl-2.0-only': 'LGPL-2.0-only',
  'lgpl-2.0-or-later': 'LGPL-2.0-or-later',
  'lgpl-2.1-only': 'LGPL-2.1-only',
  'lgpl-2.1-or-later': 'LGPL-2.1-or-later',
  'lgpl-3.0-only': 'LGPL-3.0-only',
  'lgpl-3.0-or-later': 'LGPL-3.0-or-later',
  'sspl-1.0': 'SSPL-1.0',
  'busl-1.1': 'BUSL-1.1',
};

/// pub.dev `license:` tag suffixes that are badges, not licence
/// identifiers, and never reach [pubDevTagToSpdx].
const Set<String> pubDevNonLicenceTags = <String>{
  'fsf-libre',
  'osi-approved',
  'unknown',
};
