import 'dart:io';

import 'package:test/test.dart';
import 'package:tooling/src/web_smoke_command.dart';

void main() {
  group('deleteTempDirBestEffort', () {
    test('deletes a directory with contents', () async {
      final dir = Directory.systemTemp.createTempSync('cleanup_ok_');
      File('${dir.path}/a.txt').writeAsStringSync('x');

      await deleteTempDirBestEffort(dir);

      expect(dir.existsSync(), isFalse);
    });

    test('does nothing when the directory is already gone', () async {
      final dir = Directory.systemTemp.createTempSync('cleanup_gone_')
        ..deleteSync();

      await expectLater(deleteTempDirBestEffort(dir), completes);
    });

    test('retries, then gives up without throwing when deletion keeps '
        'failing', () async {
      final dir = Directory.systemTemp.createTempSync('cleanup_busy_');
      addTearDown(() => dir.deleteSync(recursive: true));
      var calls = 0;
      const retries = 3;

      await expectLater(
        deleteTempDirBestEffort(
          dir,
          attempts: retries,
          pause: Duration.zero,
          delete: (_) {
            calls++;
            throw FileSystemException('Directory not empty', dir.path);
          },
        ),
        completes,
      );
      expect(calls, retries);
      expect(dir.existsSync(), isTrue);
    });

    test('succeeds once a transient failure clears', () async {
      final dir = Directory.systemTemp.createTempSync('cleanup_flaky_');
      var calls = 0;

      await deleteTempDirBestEffort(
        dir,
        pause: Duration.zero,
        delete: (d) {
          calls++;
          if (calls == 1) {
            throw FileSystemException('Directory not empty', d.path);
          }
          d.deleteSync(recursive: true);
        },
      );

      expect(dir.existsSync(), isFalse);
    });
  });
}
