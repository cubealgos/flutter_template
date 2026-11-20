import 'package:test/test.dart';
import 'package:tooling/src/linux_desktop_entry.dart';

void main() {
  test('fills Name, Exec and Icon from its arguments', () {
    final entry = buildLinuxDesktopEntry(
      name: 'app',
      execName: 'app',
      iconId: 'de.example.app',
    );

    expect(entry, contains('[Desktop Entry]'));
    expect(entry, contains('Name=app'));
    expect(entry, contains('Exec=app'));
    expect(entry, contains('Icon=de.example.app'));
  });

  test('is deterministic (same inputs, byte-identical output)', () {
    final first = buildLinuxDesktopEntry(
      name: 'app',
      execName: 'app',
      iconId: 'de.example.app',
    );
    final second = buildLinuxDesktopEntry(
      name: 'app',
      execName: 'app',
      iconId: 'de.example.app',
    );

    expect(second, first);
  });
}
