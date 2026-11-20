import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/dry_run_ledger.dart';
import 'package:appwrite_tool/src/git_inspector.dart';
import 'package:appwrite_tool/src/promoter.dart';
import 'package:test/test.dart';

import 'fakes/fake_git_inspector.dart';
import 'fakes/memory_dry_run_ledger.dart';
import 'fakes/recording_promotion_actions.dart';

Promoter _promoter({
  required GitInspector git,
  required PromotionActions actions,
  required DryRunLedger ledger,
}) => Promoter(
  git: git,
  actions: actions,
  ledger: ledger,
  schema: templateSchema,
  log: <String>[].add,
);

void main() {
  test('refuses an untagged HEAD before doing anything', () async {
    final actions = RecordingPromotionActions();

    await expectLater(
      _promoter(
        git: FakeGitInspector(tag: null),
        actions: actions,
        ledger: MemoryDryRunLedger(),
      ).run(dryRun: true),
      throwsA(isA<PromotionRefusedException>()),
    );
    expect(actions.calls, isEmpty);
  });

  test('refuses a dirty working tree', () async {
    final actions = RecordingPromotionActions();

    await expectLater(
      _promoter(
        git: FakeGitInspector(clean: false),
        actions: actions,
        ledger: MemoryDryRunLedger(),
      ).run(dryRun: true),
      throwsA(isA<PromotionRefusedException>()),
    );
    expect(actions.calls, isEmpty);
  });

  test('a real run without a prior dry run is refused', () async {
    final actions = RecordingPromotionActions();

    await expectLater(
      _promoter(
        git: FakeGitInspector(),
        actions: actions,
        ledger: MemoryDryRunLedger(),
      ).run(dryRun: false),
      throwsA(
        isA<PromotionRefusedException>().having(
          (e) => e.reason,
          'reason',
          contains('dry run'),
        ),
      ),
    );
    expect(actions.calls, isEmpty);
  });

  test('dry run then real run: schema, functions, then sites', () async {
    final actions = RecordingPromotionActions();
    final ledger = MemoryDryRunLedger();
    final promoter = _promoter(
      git: FakeGitInspector(),
      actions: actions,
      ledger: ledger,
    );

    expect(await promoter.run(dryRun: true), isTrue);
    expect(actions.calls.every((c) => c.contains('dry=true')), isTrue);
    actions.calls.clear();

    expect(await promoter.run(dryRun: false), isTrue);
    expect(actions.calls, <String>[
      'provision(dry=false)',
      'function api(dry=false)',
      'function hooks(dry=false)',
      'site app(dry=false)',
      'site website(dry=false)',
    ]);
  });

  test('stops at the first failure and records no dry run', () async {
    final actions = RecordingPromotionActions(failFunction: 'api');
    final ledger = MemoryDryRunLedger();

    final ok = await _promoter(
      git: FakeGitInspector(),
      actions: actions,
      ledger: ledger,
    ).run(dryRun: true);

    expect(ok, isFalse);
    expect(actions.calls.any((c) => c.startsWith('site')), isFalse);
    expect(ledger.shas, isEmpty);
  });

  test('FileDryRunLedger remembers per scope and commit', () {
    final dir = Directory.systemTemp.createTempSync('ledger');
    addTearDown(() => dir.deleteSync(recursive: true));
    final ledger = FileDryRunLedger(dir, scope: 'prod')..record('abc');

    expect(ledger.has('abc'), isTrue);
    expect(ledger.has('def'), isFalse);
    expect(FileDryRunLedger(dir, scope: 'other').has('abc'), isFalse);
  });
}
