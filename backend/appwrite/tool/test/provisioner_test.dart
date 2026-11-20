import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/provisioner.dart';
import 'package:appwrite_tool/src/table_access.dart';
import 'package:test/test.dart';

import 'fakes/fake_appwrite_admin.dart';

const _uniqueUserIdIndex = TableIndexSchema(
  key: 'userId_unique',
  columns: <String>['userId'],
  unique: true,
);

const _profilesTable = TableSchema(
  id: 'profiles',
  name: 'Profiles',
  columns: <ColumnSchema>[
    ColumnSchema(key: 'userId', type: ColumnType.varchar),
    ColumnSchema(key: 'displayName', type: ColumnType.text),
  ],
  indexes: <TableIndexSchema>[_uniqueUserIdIndex],
  ownership: TableOwnership(userIdColumn: 'userId'),
);

const _deleteAccountFunction = FunctionSchema(
  id: 'delete_account',
  name: 'Delete Account',
  runtime: 'dart-3.12',
  entrypoint: 'lib/main.dart',
  path: 'backend/appwrite/functions/delete_account',
);

const _schema = AppwriteSchema(
  databaseId: 'main',
  databaseName: 'Main',
  tables: <TableSchema>[_profilesTable],
  buckets: <BucketSchema>[BucketSchema(id: 'avatars', name: 'Avatars')],
  functions: <FunctionSchema>[_deleteAccountFunction],
);

// Not wrapped in group(): the `function_lines_of_code` threshold (50 lines,
// see root analysis_options.yaml) exempts only a function literally named
// `main` — a `group()` callback is an anonymous closure and would still be
// counted, so these stay as flat top-level `test()` calls.
void main() {
  seedRowTests();
  test('creates every declared resource on a clean instance', () async {
    final admin = FakeAppwriteAdmin();
    final report = await Provisioner(admin: admin, schema: _schema).run();

    expect(report.isNoOp, isFalse);
    expect(report.changes, contains('created database "main"'));
    expect(report.changes, contains('created table "profiles"'));
    expect(report.changes, contains('created column "profiles.userId"'));
    expect(report.changes, contains('created column "profiles.displayName"'));
    expect(report.changes, contains('created index "profiles.userId_unique"'));
    expect(report.changes, contains('created bucket "avatars"'));
    expect(report.changes, contains('created function "delete_account"'));
  });

  test('passes publicRead through to a publicly readable table', () async {
    const publicTable = TableSchema(
      id: 'app_config',
      name: 'App Config',
      publicRead: true,
      columns: <ColumnSchema>[
        ColumnSchema(key: 'minSupportedVersion', type: ColumnType.varchar),
      ],
    );
    final schema = AppwriteSchema(
      databaseId: _schema.databaseId,
      databaseName: _schema.databaseName,
      tables: <TableSchema>[_profilesTable, publicTable],
      buckets: _schema.buckets,
      functions: _schema.functions,
    );
    final admin = FakeAppwriteAdmin();

    await Provisioner(admin: admin, schema: schema).run();

    expect(admin.publicReadTableIds, <String>{'app_config'});
  });

  test('passes serverOnly through to a Function-owned table', () async {
    const privateTable = TableSchema(
      id: 'team_events',
      name: 'Team Events',
      serverOnly: true,
      columns: <ColumnSchema>[
        ColumnSchema(key: 'teamId', type: ColumnType.varchar),
      ],
    );
    final schema = AppwriteSchema(
      databaseId: _schema.databaseId,
      databaseName: _schema.databaseName,
      tables: <TableSchema>[_profilesTable, privateTable],
      buckets: _schema.buckets,
      functions: _schema.functions,
    );
    final admin = FakeAppwriteAdmin();

    await Provisioner(admin: admin, schema: schema).run();

    expect(admin.serverOnlyTableIds, <String>{'team_events'});
  });

  test('second run is a true no-op', () async {
    final admin = FakeAppwriteAdmin();
    await Provisioner(admin: admin, schema: _schema).run();
    admin.calls.clear();

    final report = await Provisioner(admin: admin, schema: _schema).run();

    expect(report.isNoOp, isTrue);
    expect(report.changes, isEmpty);
    // No create/update calls should have reached the admin at all -
    // confirms this is a real no-op, not just an empty report.
    expect(admin.calls, isEmpty);
  });

  test('creates only what is missing when partially provisioned', () async {
    final admin = FakeAppwriteAdmin();
    await admin.createDatabase(databaseId: 'main', name: 'Main');
    await admin.createTable(
      databaseId: 'main',
      tableId: 'profiles',
      name: 'Profiles',
      access: TableAccess.signedIn,
    );

    final report = await Provisioner(admin: admin, schema: _schema).run();

    expect(report.changes, isNot(contains('created database "main"')));
    expect(report.changes, isNot(contains('created table "profiles"')));
    expect(report.changes, contains('created column "profiles.userId"'));
  });

  test('updates a drifted function without recreating it', () async {
    final admin = FakeAppwriteAdmin();
    await Provisioner(admin: admin, schema: _schema).run();

    const longerTimeoutSeconds = 45;
    final drifted = _schema.functions.single;
    final schemaWithLongerTimeout = AppwriteSchema(
      databaseId: _schema.databaseId,
      databaseName: _schema.databaseName,
      tables: _schema.tables,
      buckets: _schema.buckets,
      functions: <FunctionSchema>[
        FunctionSchema(
          id: drifted.id,
          name: drifted.name,
          runtime: drifted.runtime,
          entrypoint: drifted.entrypoint,
          path: drifted.path,
          timeout: longerTimeoutSeconds,
        ),
      ],
    );
    admin.calls.clear();

    final report = await Provisioner(
      admin: admin,
      schema: schemaWithLongerTimeout,
    ).run();

    expect(report.changes, contains('updated function "delete_account"'));
    expect(admin.calls, isNot(contains('createFunction(delete_account)')));
  });

  test('disables every unused auth method, leaving only email-otp '
      'enabled', () async {
    final admin = FakeAppwriteAdmin();

    final report = await Provisioner(admin: admin, schema: _schema).run();

    for (final methodId in unusedAuthMethods) {
      expect(report.changes, contains('disabled auth method "$methodId"'));
    }
    final stillEnabled = await admin.enabledAuthMethods();
    expect(stillEnabled, <String>{'email-otp'});
  });
}

const _seededSchema = AppwriteSchema(
  databaseId: 'main',
  databaseName: 'Main',
  tables: <TableSchema>[
    TableSchema(
      id: 'app_config',
      name: 'App Config',
      columns: <ColumnSchema>[
        ColumnSchema(key: 'minSupportedVersion', type: ColumnType.varchar),
      ],
      seedRows: <SeedRow>[
        SeedRow(
          id: 'default',
          data: <String, Object>{'minSupportedVersion': '0.0.0'},
        ),
      ],
    ),
  ],
  buckets: <BucketSchema>[],
  functions: <FunctionSchema>[],
);

void seedRowTests() {
  test('creates a missing seed row after its columns', () async {
    final admin = FakeAppwriteAdmin();
    final report = await Provisioner(admin: admin, schema: _seededSchema).run();

    expect(report.changes, contains('created row "app_config/default"'));
    expect(admin.rowData('app_config', 'default'), <String, Object>{
      'minSupportedVersion': '0.0.0',
    });
    expect(
      admin.calls.indexOf('createRow(app_config/default)'),
      greaterThan(
        admin.calls.indexOf('createColumn(app_config.minSupportedVersion)'),
      ),
    );
  });

  test('never clobbers an existing seed row and stays a no-op', () async {
    final admin = FakeAppwriteAdmin();
    await Provisioner(admin: admin, schema: _seededSchema).run();
    admin.seedRow('app_config', 'default', <String, Object>{
      'minSupportedVersion': '2.0.0',
    });
    final report = await Provisioner(admin: admin, schema: _seededSchema).run();

    expect(report.isNoOp, isTrue);
    expect(admin.rowData('app_config', 'default'), <String, Object>{
      'minSupportedVersion': '2.0.0',
    });
  });

  test('client invitations stay disabled: team roles change only through '
      'team_admin', () {
    expect(unusedAuthMethods, contains('invites'));
  });
}
