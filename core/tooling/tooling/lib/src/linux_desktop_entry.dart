/// Builds a freedesktop.org Desktop Entry (see the [Desktop Entry
/// Specification](https://specifications.freedesktop.org/desktop-entry-spec/latest/))
/// for [name] (display name, from the app's `pubspec.yaml` `name:` — see
/// CLAUDE.md's clone-and-rename workflow), [execName] and [iconId] (both
/// from `linux_cmake_ids.dart`'s `readLinuxCmakeIds`, not imported here to
/// keep this file's own dependency list to what it actually calls). Pure
/// and fully deterministic — running it twice with the same inputs
/// produces byte-identical output, which is what makes regenerating
/// `linux/app.desktop` on every `icons` run safe (a full overwrite, not a
/// patch — unlike `index_html_icon_patch.dart`, this file has no
/// independent, hand-authored content to preserve).
String buildLinuxDesktopEntry({
  required String name,
  required String execName,
  required String iconId,
}) =>
    '''
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Exec=$execName
Icon=$iconId
Terminal=false
Categories=Utility;
''';
