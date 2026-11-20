/// Compares two plain dotted-integer version strings (`'1.2.3'`), the same
/// shape a `pubspec.yaml` version or an app's own build version uses.
///
/// Deliberately not a dependency on `package:pub_semver` (which parses full
/// semver, including pre-release/build-metadata suffixes this template's
/// one comparison — "is the running app at least this old?" — never needs)
/// or on any platform version API. Returns a negative number if [first] is
/// older than [second], zero if equal, positive if newer — same contract as
/// [Comparable.compareTo]. A missing segment (e.g. `'1.2'` vs `'1.2.0'`) is
/// treated as `0`; a non-numeric segment is treated as `0` too, rather than
/// throwing — a malformed backend-supplied version string should degrade
/// to "not blocked", never crash the bootstrap screen.
int compareDottedVersions(String first, String second) {
  final firstParts = first.split('.');
  final secondParts = second.split('.');
  final length = firstParts.length > secondParts.length
      ? firstParts.length
      : secondParts.length;

  for (var i = 0; i < length; i++) {
    final firstSegment = i < firstParts.length
        ? int.tryParse(firstParts[i]) ?? 0
        : 0;
    final secondSegment = i < secondParts.length
        ? int.tryParse(secondParts[i]) ?? 0
        : 0;
    final comparison = firstSegment.compareTo(secondSegment);
    if (comparison != 0) return comparison;
  }

  return 0;
}
