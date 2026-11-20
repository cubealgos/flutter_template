import 'package:api/src/action_context.dart';
import 'package:api/src/actions/team_admin/team_history_retention_job.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:teams/teams.dart';
import 'package:test/test.dart';

const _ada = TeamActor(userId: 'ada', email: 'ada@example.com');

ActionContext _context(Map<String, String> environment) => ActionContext(
  callerUserId: null,
  body: const <String, dynamic>{},
  environment: environment,
  client: Client(),
);

/// A backend with one team created 400 days ago, and a job over it.
Future<({FakeTeamBackend backend, TeamHistoryRetentionJob job})> _aged() async {
  final backend = FakeTeamBackend();
  await backend.serviceFor(_ada).createTeam('Acme');
  backend.advance(const Duration(days: 400));

  return (
    backend: backend,
    job: TeamHistoryRetentionJob(engineFor: (_) => backend.engine),
  );
}

Future<List<String?>> _emails(FakeTeamBackend backend) async {
  final team = (await backend.serviceFor(_ada).listTeams()).single;
  final events = await backend.store.eventsOfTeam(team.id);

  return [for (final e in events) e.subjectEmail];
}

Future<List<String?>> _runWith(Map<String, String> environment) async {
  final aged = await _aged();
  await aged.job.run(_context(environment), slot: 1);

  return await _emails(aged.backend);
}

void main() {
  test('does nothing when no retention is configured (the default)', () async {
    expect(await _runWith(const {}), <String?>['ada@example.com']);
  });

  test('replaces snapshots older than the configured days', () async {
    expect(await _runWith({teamHistoryRetentionEnvKey: '365'}), <String?>[
      MembershipEvent.formerMember,
    ]);
  });

  test('keeps snapshots still inside the period', () async {
    expect(await _runWith({teamHistoryRetentionEnvKey: '500'}), <String?>[
      'ada@example.com',
    ]);
  });

  test(
    'a set but invalid period fails the job instead of being ignored',
    () async {
      final job = (await _aged()).job;
      for (final bad in ['abc', '0', '-5', '1.5']) {
        expect(
          () => job.run(_context({teamHistoryRetentionEnvKey: bad}), slot: 1),
          throwsFormatException,
          reason: bad,
        );
      }
    },
  );

  test('declares scopes the Function key has', () async {
    final job = (await _aged()).job;

    expect(job.scopes, containsAll(<String>['tables.read', 'tables.write']));
  });
}
