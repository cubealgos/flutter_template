/// The two `set(...)` values `icons_command.dart` reads out of
/// `linux/CMakeLists.txt` to build a `.desktop` entry and its matching
/// icon-theme install paths — see [readLinuxCmakeIds].
class LinuxCmakeIds {
  /// Creates a value holding [binaryName] and [applicationId].
  const LinuxCmakeIds({required this.binaryName, required this.applicationId});

  /// `BINARY_NAME` — the on-disk executable name, used as the `.desktop`
  /// entry's `Exec=`.
  final String binaryName;

  /// `APPLICATION_ID` — the GTK application/icon-theme identifier, used as
  /// the `.desktop` entry's `Icon=` and the install name under
  /// `share/icons/hicolor/<size>x<size>/apps/`.
  final String applicationId;
}

final RegExp _binaryNamePattern = RegExp(r'''set\(BINARY_NAME\s+"([^"]+)"\)''');
final RegExp _applicationIdPattern = RegExp(
  r'''set\(APPLICATION_ID\s+"([^"]+)"\)''',
);

/// Extracts [LinuxCmakeIds] from [cmakeListsContent] (`linux/CMakeLists.txt`'s
/// text). Pure — no filesystem access — so `linux_cmake_ids_test.dart`
/// exercises it in-process against literal fixture strings. Throws a
/// [FormatException] if either `set(...)` line isn't found: a Flutter-
/// generated `linux/CMakeLists.txt` always has both, so their absence means
/// the file was hand-edited into an unexpected shape.
LinuxCmakeIds readLinuxCmakeIds(String cmakeListsContent) {
  final binaryMatch = _binaryNamePattern.firstMatch(cmakeListsContent);
  if (binaryMatch == null) {
    throw const FormatException(
      'linux/CMakeLists.txt: no `set(BINARY_NAME "...")` line found.',
    );
  }
  final applicationIdMatch = _applicationIdPattern.firstMatch(
    cmakeListsContent,
  );
  if (applicationIdMatch == null) {
    throw const FormatException(
      'linux/CMakeLists.txt: no `set(APPLICATION_ID "...")` line found.',
    );
  }

  return LinuxCmakeIds(
    // The regex's capture group can only fail to participate if the
    // pattern itself didn't match, which the two null checks above already
    // ruled out — so this reads the match's own guarantee, not an assumed
    // one, the same idiom `map_generator.dart`'s `loadMembers` uses for a
    // required pubspec field.
    binaryName:
        binaryMatch.group(1) ??
        (throw const FormatException(
          'linux/CMakeLists.txt: BINARY_NAME capture group empty.',
        )),
    applicationId:
        applicationIdMatch.group(1) ??
        (throw const FormatException(
          'linux/CMakeLists.txt: APPLICATION_ID capture group empty.',
        )),
  );
}
