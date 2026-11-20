import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/flutter_sdk_locator.dart';

import 'support/temp_workspace.dart';

void main() {
  group('resolveFlutterSdkRoot', () {
    test('walks up from bin/cache/dart-sdk/bin/dart to the SDK root', () {
      final dartPath = p.join(
        '/opt',
        'flutter',
        'bin',
        'cache',
        'dart-sdk',
        'bin',
        'dart',
      );

      expect(resolveFlutterSdkRoot(dartPath), p.join('/opt', 'flutter'));
    });

    test('throws CommandFailure for a non-Flutter-vendored dart', () {
      final dartPath = p.join('/usr', 'local', 'bin', 'dart');

      expect(
        () => resolveFlutterSdkRoot(dartPath),
        throwsA(isA<CommandFailure>()),
      );
    });
  });

  group('flutterSdkVersion', () {
    // Assigned in setUp/read throughout the tests, cleaned up in tearDown
    // — the standard package:test fixture-per-test pattern.
    // ignore: solid_lints/avoid_late_keyword
    late TempWorkspace workspace;

    setUp(() => workspace = TempWorkspace.create('flutter_sdk_locator_'));
    tearDown(() => workspace.dispose());

    test('reads frameworkVersion from bin/cache/flutter.version.json', () {
      workspace.writeFile(
        p.join('bin', 'cache', 'flutter.version.json'),
        jsonEncode({'frameworkVersion': '3.47.5', 'channel': 'stable'}),
      );

      expect(flutterSdkVersion(workspace.root.path), '3.47.5');
    });

    test('throws CommandFailure if the version file is missing', () {
      expect(
        () => flutterSdkVersion(workspace.root.path),
        throwsA(isA<CommandFailure>()),
      );
    });

    test('throws CommandFailure if frameworkVersion is missing', () {
      workspace.writeFile(
        p.join('bin', 'cache', 'flutter.version.json'),
        jsonEncode({'channel': 'stable'}),
      );

      expect(
        () => flutterSdkVersion(workspace.root.path),
        throwsA(isA<CommandFailure>()),
      );
    });

    test('throws CommandFailure on unparseable JSON', () {
      workspace.writeFile(
        p.join('bin', 'cache', 'flutter.version.json'),
        'not json',
      );

      expect(
        () => flutterSdkVersion(workspace.root.path),
        throwsA(isA<CommandFailure>()),
      );
    });
  });
}
