/// One component this app's dependency closure resolves to — see
/// `dependency_graph.dart`'s `GraphPackage` (SBOM components are built
/// from those, one-to-one, plus the version/licence resolution
/// `sbom_command.dart` layers on top).
class SbomComponent {
  /// Creates a component.
  const SbomComponent({
    required this.type,
    required this.name,
    required this.version,
    required this.purl,
    this.sha256,
    this.licences = const [],
  });

  /// The CycloneDX component `type` (`library` for an ordinary pub
  /// dependency or first-party workspace member, `framework` for a piece
  /// of the Flutter SDK itself — see `sbom_command.dart`).
  final String type;

  /// The package name.
  final String name;

  /// The resolved version.
  final String version;

  /// This component's package-url — `pkg:pub/<name>@<version>` for a real
  /// pub.dev package, `pkg:generic/...` for a first-party workspace
  /// member or a piece of the Flutter SDK (neither is actually published
  /// to pub.dev, so a `pkg:pub` purl for either would assert something
  /// false — see `sbom_command.dart`'s component-building code).
  final String purl;

  /// Every licence pub.dev (or a `verified:` override) reports — empty
  /// when nothing is known (pub.dev reported nothing, and no override
  /// covers this exact version), a first-party component (its own code
  /// isn't a third-party licence obligation), or the CycloneDX schema's
  /// component `licenses` key is simply omitted.
  final List<SbomLicence> licences;

  /// The SHA-256 hash `pubspec.lock` recorded for this exact
  /// (name, version), if any — never present for a first-party or
  /// Flutter-SDK component (neither has a lockfile hash).
  final String? sha256;

  /// This component as a CycloneDX `component` object
  /// (`#/definitions/component`).
  Map<String, Object> toJson() => {
    'type': type,
    'bom-ref': purl,
    'name': name,
    'version': version,
    'purl': purl,
    if (sha256 != null)
      'hashes': [
        {'alg': 'SHA-256', 'content': sha256},
      ],
    if (licences.isNotEmpty)
      'licenses': [for (final licence in licences) licence.toJson()],
  };
}

/// One SBOM component's licence, as CycloneDX's `license` object
/// (`#/definitions/license`) represents it: either a recognised SPDX
/// identifier (`id`) or, when pub.dev reported an unrecognised `license:`
/// tag this workspace has no SPDX mapping for, free text (`name`) — the
/// schema requires exactly one of the two, never both.
class SbomLicence {
  /// A recognised SPDX identifier (e.g. `MIT`), emitted as the `license`
  /// object's `id`.
  const SbomLicence.spdx(this.value) : isSpdxId = true;

  /// Free-text licence info pub.dev couldn't map to an SPDX id, emitted
  /// as the `license` object's `name`.
  const SbomLicence.freeText(this.value) : isSpdxId = false;

  /// The SPDX id or free-text label itself.
  final String value;

  /// True if [value] is emitted as `id` rather than `name`.
  final bool isSpdxId;

  /// This licence as a CycloneDX `license` wrapper object
  /// (`{"license": {...}}` — the shape `licenseChoice`'s "multiple
  /// licenses" branch requires for each entry).
  Map<String, Object> toJson() => {
    'license': {isSpdxId ? 'id' : 'name': value},
  };
}
