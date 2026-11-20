import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/new_feature_command.dart';
import 'package:tooling/src/process_runner.dart';

// The router fixture needs literal `$` signs.
const String _router = r'''
import 'package:app/features/home/home_view.dart';
import 'package:app/features/settings/privacy/privacy_settings_view.dart';
import 'package:app/features/sign_in/sign_in_view.dart';
import 'package:flutter/widgets.dart';

part 'router.g.dart';

@TypedGoRoute<BootstrapRoute>(
  path: '/',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<HomeRoute>(path: 'home'),
    TypedGoRoute<PrivacySettingsRoute>(path: 'settings/privacy'),
  ],
)
class BootstrapRoute extends GoRouteData with $BootstrapRoute {
  const BootstrapRoute();
}

/// Privacy.
class PrivacySettingsRoute extends GoRouteData with $PrivacySettingsRoute {
  const PrivacySettingsRoute();
}
''';

// This file is named for the command under test; the only class declared
// here is a private fake runner.
// ignore: solid_lints/prefer_match_file_name
class _FakeFormatter implements ProcessRunner {
  final List<List<String>> calls = <List<String>>[];

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    calls.add(arguments);

    return ProcessResult(0, 0, '', '');
  }
}

void main() {
  // Assigned in setUp, the standard package:test fixture pattern.
  // ignore_for_file: solid_lints/avoid_late_keyword
  late Directory root;
  late _FakeFormatter formatter;
  late List<String> out;
  late List<String> err;

  setUp(() {
    root = Directory.systemTemp.createTempSync('new_feature_test');
    formatter = _FakeFormatter();
    out = <String>[];
    err = <String>[];
    Directory(p.join(root.path, 'apps/app/lib/features/settings/privacy'))
        .createSync(recursive: true);
    Directory(p.join(root.path, 'apps/app/lib/app'))
        .createSync(recursive: true);
    File(p.join(root.path, 'apps/app/pubspec.yaml'))
        .writeAsStringSync('name: app\n');
    File(p.join(root.path, 'apps/app/lib/app/router.dart'))
        .writeAsStringSync(_router);
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<int> run(List<String> args) => NewFeatureCommand(
    runner: formatter,
    out: out.add,
    err: err.add,
  ).run(args, repoRoot: root.path);

  String read(String relative) =>
      File(p.join(root.path, relative)).readAsStringSync();

  String treeSnapshot() => root
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => '${f.path}:${f.readAsStringSync().hashCode}')
      .join('\n');

  test('creates the feature files, tests and the route', () async {
    expect(await run(<String>['settings/notifications']), 0);

    const lib = 'apps/app/lib/features/settings/notifications';
    const test = 'apps/app/test/features/settings/notifications';
    for (final f in <String>[
      '$lib/notifications_model.dart',
      '$lib/notifications_controller.dart',
      '$lib/notifications_view.dart',
      '$lib/layouts/notifications_mobile_layout.dart',
      '$test/notifications_view_test.dart',
      '$test/layouts/notifications_mobile_layout_test.dart',
    ]) {
      expect(File(p.join(root.path, f)).existsSync(), isTrue, reason: f);
    }
    final view = read('$lib/notifications_view.dart');
    expect(view, contains('class NotificationsView'));
    expect(view, contains("import 'package:app/app/di.dart';"));
    expect(
      read('$test/notifications_view_test.dart'),
      contains("import '../../../support/screen_harness.dart';"),
    );
    expect(
      read('$test/layouts/notifications_mobile_layout_test.dart'),
      contains("import '../../../../support/layout_harness.dart';"),
    );
    expect(formatter.calls.single.first, 'format');
  });

  test('wires the import, route entry and class into router.dart', () async {
    await run(<String>['settings/push_alerts']);

    final router = read('apps/app/lib/app/router.dart');
    expect(
      router,
      contains(
        "TypedGoRoute<PushAlertsRoute>(path: 'settings/push-alerts'),\n  ],",
      ),
    );
    expect(router, contains('class PushAlertsRoute extends GoRouteData'));
    final imports = router
        .split('\n')
        .where((l) => l.startsWith("import 'package:app/"))
        .toList();
    expect(imports, <String>[
      "import 'package:app/features/home/home_view.dart';",
      "import 'package:app/features/settings/privacy/privacy_settings_view.dart';",
      "import 'package:app/features/settings/push_alerts/push_alerts_view.dart';",
      "import 'package:app/features/sign_in/sign_in_view.dart';",
    ]);
  });

  test('a top-level feature gets a top-level route path', () async {
    expect(await run(<String>['help_centre']), 0);
    expect(
      read('apps/app/lib/app/router.dart'),
      contains("TypedGoRoute<HelpCentreRoute>(path: 'help-centre')"),
    );
  });

  test('prints the snippet instead when router.dart has no anchor', () async {
    File(p.join(root.path, 'apps/app/lib/app/router.dart'))
        .writeAsStringSync('// nothing here\n');

    expect(await run(<String>['settings/notifications']), 0);

    expect(read('apps/app/lib/app/router.dart'), '// nothing here\n');
    final printed = out.join('\n');
    expect(printed, contains('Did not edit'));
    expect(
      printed,
      contains(
        "TypedGoRoute<NotificationsRoute>(path: 'settings/notifications')",
      ),
    );
    expect(printed, contains('class NotificationsRoute extends GoRouteData'));
  });

  group('refuses', () {
    Future<void> expectRefusal(String path, String message) async {
      final before = treeSnapshot();
      expect(await run(<String>[path]), isNonZero);
      expect(err.join('\n'), contains(message));
      expect(treeSnapshot(), before, reason: 'nothing may be written');
    }

    test('an existing feature path', () async {
      await expectRefusal('settings/privacy', 'already exists');
    });

    test('an existing test path', () async {
      Directory(p.join(root.path, 'apps/app/test/features/settings/stale'))
          .createSync(recursive: true);
      await expectRefusal('settings/stale', 'already exists');
    });

    for (final reserved in <String>['widgets', 'layouts', 'steps']) {
      test('the reserved segment $reserved (anywhere)', () async {
        await expectRefusal('settings/$reserved', 'reserved');
        await expectRefusal('$reserved/thing', 'reserved');
      });
    }

    for (final bad in <String>[
      'settings/Notifications',
      'Settings/notifications',
      'settings/push-alerts',
      'settings/push__alerts',
      'settings/_alerts',
      'settings/1alerts',
      'settings//alerts',
      '/settings/alerts',
      'settings/alerts/',
    ]) {
      test('the non-snake_case or malformed path $bad', () async {
        await expectRefusal(bad, 'Invalid feature path');
      });
    }

    test('a missing parent feature', () async {
      await expectRefusal('nowhere/thing', 'Parent feature "nowhere"');
    });

    test('a route class router.dart already declares', () async {
      await expectRefusal('settings/privacy_settings', 'already');
    });
  });

  test('refuses a wrong argument count with the usage exit code', () async {
    expect(await run(<String>[]), usageExitCode);
    expect(await run(<String>['a', 'b']), usageExitCode);
    expect(err.first, contains('Usage'));
  });
}
