import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/dry_run_admin.dart';
import 'package:appwrite_tool/src/provisioner.dart';
import 'package:test/test.dart';

import 'fakes/fake_appwrite_admin.dart';

void main() {
  test('a dry run reports every change but sends none', () async {
    final real = FakeAppwriteAdmin();

    final report = await Provisioner(
      admin: DryRunAdmin(real),
      schema: templateSchema,
    ).run();

    expect(report.changes, isNotEmpty);
    expect(report.changes.join('\n'), contains('created table "profiles"'));
    expect(
      real.calls.where((c) => c.startsWith('create')),
      isEmpty,
      reason: 'nothing may reach the real admin',
    );
  });

  test('a dry run against a provisioned project is a no-op', () async {
    final real = FakeAppwriteAdmin();
    await Provisioner(admin: real, schema: templateSchema).run();

    final report = await Provisioner(
      admin: DryRunAdmin(real),
      schema: templateSchema,
    ).run();

    expect(report.isNoOp, isTrue);
  });
}
