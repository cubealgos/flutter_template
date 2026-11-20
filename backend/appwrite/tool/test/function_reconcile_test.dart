import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/dry_run_admin.dart';
import 'package:appwrite_tool/src/provisioner.dart';
import 'package:test/test.dart';

import 'fakes/fake_appwrite_admin.dart';

const _api = FunctionSchema(
  id: 'api',
  name: 'API',
  runtime: 'dart-3.12',
  entrypoint: 'lib/main.dart',
  path: 'backend/appwrite/functions/api',
);

const _schema = AppwriteSchema(
  databaseId: 'main',
  databaseName: 'Main',
  tables: <TableSchema>[],
  buckets: <BucketSchema>[],
  functions: <FunctionSchema>[_api],
);

// Flat top-level tests, see provisioner_test.dart's note on the
// `function_lines_of_code` threshold.
const int _strays = 2;

void main() {
  test('deletes a Function the schema does not declare, before creating '
      'api (the Free plan allows 2 Functions)', () async {
    final admin = FakeAppwriteAdmin()
      ..seedFunction('delete_account')
      ..seedFunction('review_demo_sign_in');

    final report = await Provisioner(admin: admin, schema: _schema).run();

    expect(report.changes.first, startsWith('deleted function "delete_'));
    expect(report.changes, contains('created function "api"'));
    expect(admin.functionIds, <String>{'api'});
    expect(
      admin.calls.indexOf('deleteFunction(review_demo_sign_in)'),
      lessThan(admin.calls.indexOf('createFunction(api)')),
      reason: 'the slots must be freed before api is created',
    );
  });

  test('never deletes a Function the schema declares', () async {
    final admin = FakeAppwriteAdmin()
      ..seedFunction('api')
      ..seedFunction('delete_account');

    final report = await Provisioner(admin: admin, schema: _schema).run();

    expect(admin.calls, isNot(contains('deleteFunction(api)')));
    expect(admin.calls, contains('deleteFunction(delete_account)'));
    expect(admin.functionIds, contains('api'));
    expect(report.changes.where((c) => c.startsWith('deleted')), <String>[
      'deleted function "delete_account" (not in the schema)',
    ]);
  });

  test('never deletes any declared Function, whatever else exists', () async {
    final admin = FakeAppwriteAdmin();
    await Provisioner(admin: admin, schema: templateSchema).run();
    admin
      ..seedFunction('stray')
      ..calls.clear();

    await Provisioner(admin: admin, schema: templateSchema).run();

    expect(admin.calls, <String>['deleteFunction(stray)']);
    expect(
      admin.functionIds,
      templateSchema.functions.map((f) => f.id).toSet(),
    );
  });

  test('a second run is a no-op once the stray Functions are gone', () async {
    final admin = FakeAppwriteAdmin()..seedFunction('delete_account');
    await Provisioner(admin: admin, schema: _schema).run();

    final report = await Provisioner(admin: admin, schema: _schema).run();

    expect(report.isNoOp, isTrue);
  });

  test('a dry run lists the deletions first and sends none', () async {
    final real = FakeAppwriteAdmin()
      ..seedFunction('delete_account')
      ..seedFunction('review_demo_sign_in');

    final report = await Provisioner(
      admin: DryRunAdmin(real),
      schema: _schema,
    ).run();

    expect(report.changes.take(_strays), <String>[
      'deleted function "delete_account" (not in the schema)',
      'deleted function "review_demo_sign_in" (not in the schema)',
    ]);
    expect(report.changes, contains('created function "api"'));
    expect(real.calls, isEmpty, reason: 'nothing may reach the real admin');
    expect(real.functionIds, <String>{'delete_account', 'review_demo_sign_in'});
  });

  test('a dry run never lists a declared Function for deletion', () async {
    final real = FakeAppwriteAdmin()..seedFunction('api');

    final report = await Provisioner(
      admin: DryRunAdmin(real),
      schema: _schema,
    ).run();

    expect(report.changes.where((c) => c.startsWith('deleted')), isEmpty);
  });

  test('a changed cron schedule counts as drift', () async {
    final admin = FakeAppwriteAdmin();
    await Provisioner(admin: admin, schema: _schema).run();
    const scheduled = AppwriteSchema(
      databaseId: 'main',
      databaseName: 'Main',
      tables: <TableSchema>[],
      buckets: <BucketSchema>[],
      functions: <FunctionSchema>[
        FunctionSchema(
          id: 'api',
          name: 'API',
          runtime: 'dart-3.12',
          entrypoint: 'lib/main.dart',
          path: 'backend/appwrite/functions/api',
          schedule: apiCronSchedule,
        ),
      ],
    );

    final report = await Provisioner(admin: admin, schema: scheduled).run();

    expect(report.changes, contains('updated function "api"'));
  });
}
