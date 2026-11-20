/// One package name from `LicenseRegistry.licenses`, with every distinct
/// licence text registered under it — a package can be named by more than
/// one `LicenseEntry` (e.g. several bundled licence files), which used to
/// produce one list row per entry (duplicate package names) instead of one
/// row per package (spec.md §2.10: "list of package names").
///
/// A plain class, not `freezed`: built once per package name from
/// `LicenseEntry`/`LicenseParagraph` (from `package:flutter/foundation.dart`),
/// neither of which have meaningful value equality of their own, so a
/// freezed wrapper would gain nothing over a small holder.
class LicenceGroup {
  /// Creates a group for [packageName], with each distinct licence text
  /// registered under it in [texts].
  const LicenceGroup({required this.packageName, required this.texts});

  /// The package name, e.g. `'flutter'`.
  final String packageName;

  /// Every distinct licence text registered under [packageName], in the
  /// order `LicenseRegistry.licenses` emitted them.
  final List<String> texts;
}
