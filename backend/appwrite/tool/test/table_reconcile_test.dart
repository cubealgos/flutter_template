import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/dry_run_admin.dart';
import 'package:appwrite_tool/src/provisioner.dart';
import 'package:appwrite_tool/src/table_access.dart';
import 'package:test/test.dart';

import 'fakes/fake_appwrite_admin.dart';

const _broad = TableSettings(
  permissions: <String>[
    'create("users")',
    'read("users")',
    'update("users")',
    'delete("users")',
  ],
  rowSecurity: true,
);

Future<FakeAppwriteAdmin> _provisioned() async {
  final admin = FakeAppwriteAdmin();
  await Provisioner(admin: admin, schema: templateSchema).run();
  admin.calls.clear();

  return admin;
}

void main() {
  test('repairs a table provisioned with the blanket grant', () async {
    final admin = await _provisioned();
    admin.seedTableSettings('profiles', _broad);

    final report = await Provisioner(
      admin: admin,
      schema: templateSchema,
    ).run();

    expect(report.changes, <String>['updated table "profiles" permissions']);
    expect(admin.calls, <String>['updateTableAccess(profiles)']);
    expect(admin.settingsOf('profiles')?.permissions, <String>[
      'create("users")',
    ]);
  });

  test('a repaired project then provisions as a no-op', () async {
    final admin = await _provisioned();
    admin.seedTableSettings('profiles', _broad);
    await Provisioner(admin: admin, schema: templateSchema).run();
    admin.calls.clear();

    final report = await Provisioner(
      admin: admin,
      schema: templateSchema,
    ).run();

    expect(report.isNoOp, isTrue);
    expect(admin.calls, isEmpty);
  });

  test(
    'a publicRead table keeps read(any) and loses the users grant',
    () async {
      final admin = await _provisioned();
      admin.seedTableSettings('app_config', _broad);

      await Provisioner(admin: admin, schema: templateSchema).run();

      expect(admin.settingsOf('app_config')?.permissions, <String>[
        'create("users")',
        'read("any")',
      ]);
    },
  );

  test('rowSecurity switched off is turned back on', () async {
    final admin = await _provisioned();
    admin.seedTableSettings(
      'profiles',
      const TableSettings(
        permissions: <String>['create("users")'],
        rowSecurity: false,
      ),
    );

    final report = await Provisioner(
      admin: admin,
      schema: templateSchema,
    ).run();

    expect(report.changes, <String>['updated table "profiles" permissions']);
    expect(admin.settingsOf('profiles')?.rowSecurity, isTrue);
  });

  test('--dry-run lists the repair and sends nothing', () async {
    final admin = await _provisioned();
    admin.seedTableSettings('profiles', _broad);

    final report = await Provisioner(
      admin: DryRunAdmin(admin),
      schema: templateSchema,
    ).run();

    expect(report.changes, <String>['updated table "profiles" permissions']);
    expect(admin.calls, isEmpty);
    expect(admin.settingsOf('profiles'), _broad);
  });

  test(
    'a server-only table is created and kept with no client grant',
    () async {
      final admin = await _provisioned();
      expect(admin.settingsOf('team_membership_events')?.permissions, isEmpty);
      admin.seedTableSettings('team_membership_events', _broad);

      final report = await Provisioner(
        admin: admin,
        schema: templateSchema,
      ).run();

      expect(report.changes, <String>[
        'updated table "team_membership_events" permissions',
      ]);
      expect(admin.settingsOf('team_membership_events')?.permissions, isEmpty);
    },
  );
}
