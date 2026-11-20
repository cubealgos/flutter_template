import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:test/test.dart';

void main() {
  _uniqueIndexTests();
  _openRowTests();
  _siteAndKeyTests();
  _functionTests();
  _teamTests();
  _serverPrimitiveTests();
  _billingTests();
}

void _uniqueIndexTests() {
  group('unique indexes', () {
    test('profiles declares a unique userId index', () {
      final profiles = templateSchema.tables.singleWhere(
        (t) => t.id == 'profiles',
      );
      final index = profiles.indexes.singleWhere(
        (i) => i.key == 'userId_unique',
      );

      expect(index.unique, isTrue);
      expect(index.columns, <String>['userId']);
    });

    test('indexes are non-unique unless declared unique', () {
      expect(
        const TableIndexSchema(key: 'k', columns: <String>['c']).unique,
        isFalse,
      );
    });

    test('oneOpenRowPerKey is a unique index over one nullable column', () {
      final index = TableIndexSchema.oneOpenRowPerKey(openKeyColumn: 'openKey');

      expect(index.unique, isTrue);
      expect(index.columns, <String>['openKey']);
      expect(index.key, 'openKey_open_unique');
    });
  });
}

void _openRowTests() {
  group('open-row pattern', () {
    test('the open-row pattern can be declared on a table', () {
      final table = TableSchema(
        id: 'jobs',
        name: 'Jobs',
        columns: const <ColumnSchema>[
          ColumnSchema(
            key: 'openKey',
            type: ColumnType.varchar,
            isRequired: false,
          ),
        ],
        indexes: <TableIndexSchema>[
          TableIndexSchema.oneOpenRowPerKey(openKeyColumn: 'openKey'),
        ],
      );

      expect(table.indexes.single.unique, isTrue);
      expect(_problems(table), isEmpty);
    });

    test('an open-row column that is required is flagged', () {
      final table = TableSchema(
        id: 'jobs',
        name: 'Jobs',
        columns: const <ColumnSchema>[
          ColumnSchema(key: 'openKey', type: ColumnType.varchar),
        ],
        indexes: <TableIndexSchema>[
          TableIndexSchema.oneOpenRowPerKey(openKeyColumn: 'openKey'),
        ],
      );

      expect(_problems(table).single, contains('must be optional'));
    });

    test('every template index is well formed', () {
      for (final table in templateSchema.tables) {
        expect(_problems(table), isEmpty, reason: table.id);
      }
    });
  });
}

void _siteAndKeyTests() {
  group('sites', () {
    test('IDs are unique and build output is repo-relative', () {
      final ids = templateSchema.sites.map((s) => s.id).toList();

      expect(ids.toSet().length, ids.length);
      for (final site in templateSchema.sites) {
        expect(site.buildOutputPath, isNot(startsWith('/')));
      }
    });
  });

  group('API keys', () {
    test('there are several, none holding the union of all scopes', () {
      final keys = templateSchema.apiKeys;
      final union = {for (final k in keys) ...k.scopes};

      expect(keys.length, greaterThan(1));
      for (final key in keys) {
        expect(key.scopes.length, lessThan(union.length), reason: key.id);
      }
    });

    test('IDs are unique and every scope is a read or write scope', () {
      final ids = templateSchema.apiKeys.map((k) => k.id).toList();

      expect(ids.toSet().length, ids.length);
      for (final scope in templateSchema.apiKeys.expand((k) => k.scopes)) {
        expect(scope, matches(RegExp(r'^[a-z.]+\.(read|write)$')));
      }
    });
  });
}

/// Structural problems of [table]'s indexes: unknown columns, and
/// open-row columns that are not optional.
List<String> _problems(TableSchema table) {
  final columns = {for (final c in table.columns) c.key: c};
  final problems = <String>[];
  for (final index in table.indexes) {
    for (final column in index.columns) {
      if (!columns.containsKey(column)) {
        problems.add('${index.key} covers unknown column "$column"');
      }
    }
    final isOpenRow = index.key.endsWith('_open_unique');
    if (isOpenRow && (columns[index.columns.single]?.isRequired ?? true)) {
      problems.add('${index.key}: column must be optional');
    }
  }

  return problems;
}

void _functionTests() {
  group('functions', () {
    test('declares at most $maxFunctions Functions (Free plan limit)', () {
      expect(
        templateSchema.functions.length,
        lessThanOrEqualTo(maxFunctions),
        reason:
            "Appwrite Cloud's Free plan allows $maxFunctions Functions per "
            'project (since 2026-01-08); a third fails with 403 '
            'additional_resource_not_allowed. Do not add a Function: add an '
            'action to the `api` router Function instead - see the '
            'decision of 2026-10-01 and "Adding an action" in '
            'backend/appwrite/README.md. `hooks` is the second Function, for '
            'public inbound webhooks.',
      );
    });

    test('only the router `api` and the reserved `hooks` are declared', () {
      final unknown = templateSchema.functions
          .map((f) => f.id)
          .where((id) => !allowedFunctionIds.contains(id));

      expect(
        unknown,
        isEmpty,
        reason:
            'Function ids must be one of $allowedFunctionIds: '
            'server-side operations are actions of `api`, public webhooks '
            'go to `hooks`.',
      );
    });

    test('api exists, is callable with no session, and has a cron tick', () {
      final api = templateSchema.functions.singleWhere((f) => f.id == 'api');

      expect(api.execute, <String>['any']);
      expect(api.schedule, apiCronSchedule);
    });
  });
}

void _teamTests() {
  group('team tenancy', () {
    TableSchema table(String id) =>
        templateSchema.tables.singleWhere((t) => t.id == id);

    test('invitations and history are server-only, shared rows are not', () {
      expect(table('team_invitations').serverOnly, isTrue);
      expect(table('team_membership_events').serverOnly, isTrue);
      expect(table('team_notes').serverOnly, isFalse);
      expect(table('team_notes').ownership, isNull);
    });

    test('every team table index covers existing columns', () {
      for (final id in [
        'team_invitations',
        'team_membership_events',
        'team_notes',
      ]) {
        expect(_problems(table(id)), isEmpty, reason: id);
      }
    });

    test('the api router declares the team scopes (team_admin action)', () {
      final api = templateSchema.functions.singleWhere((f) => f.id == 'api');

      expect(api.scopes, containsAll(<String>['teams.read', 'teams.write']));
    });

    test('the owner is never a native Appwrite owner', () {
      expect(nativeTeamRole('owner'), nativeOwnerRole);
      expect(nativeOwnerRole, isNot('owner'));
      expect(nativeTeamRole('admin'), 'admin');
      expect(nativeTeamRole('auditor'), 'auditor');
    });
  });
}

void _serverPrimitiveTests() {
  group('server primitives', () {
    TableSchema table(String id) =>
        templateSchema.tables.singleWhere((t) => t.id == id);
    // The mail tables are held to the same rules.
    const ids = [
      'jobs',
      'job_claims',
      'job_slots',
      'rate_limits',
      'mail_deliveries',
      'mail_suppressions',
      'billing_events',
      'billing_entitlements',
    ];

    test('every one is server-only and well formed', () {
      for (final id in ids) {
        expect(table(id).serverOnly, isTrue, reason: id);
        expect(_problems(table(id)), isEmpty, reason: id);
      }
    });

    test('the exactly-once rules rest on unique indexes', () {
      List<String> unique(String id) => [
        for (final i in table(id).indexes)
          if (i.unique) i.columns.join('+'),
      ];

      expect(unique('job_claims'), ['jobId+attempt']);
      expect(unique('job_slots'), ['jobName+slot']);
      expect(unique('rate_limits'), ['keyHash+windowStart+hit']);
      expect(unique('mail_deliveries'), ['keyHash']);
      expect(unique('mail_suppressions'), ['userId+subscription']);
      expect(unique('billing_events'), ['ledgerKey']);
      expect(unique('billing_entitlements'), ['subscriptionId']);
    });

    test('rate limits store only a hash, never an address', () {
      final columns = table('rate_limits').columns.map((c) => c.key);

      expect(columns, containsAll(['keyHash', 'expiresAt']));
      expect(columns, isNot(contains('ip')));
      expect(columns, isNot(contains('host')));
    });
  });
}

void _billingTests() {
  group('billing', () {
    test(
      'hooks is public, has no cron tick and holds database scopes only',
      () {
        final hooks = templateSchema.functions.singleWhere(
          (f) => f.id == 'hooks',
        );

        expect(hooks.execute, <String>['any']);
        expect(hooks.schedule, isEmpty);
        expect(hooks.path, 'backend/appwrite/functions/hooks');
        expect(
          hooks.scopes.map((s) => s.split('.').first).toSet(),
          <String>{'tables', 'collections', 'documents'},
          reason:
              'the Function that writes the billing ledger must hold no user, '
              'team, file or messaging scope',
        );
      },
    );

    test('the ledger keeps no payload and no personal column', () {
      final columns = templateSchema.tables
          .singleWhere((t) => t.id == 'billing_events')
          .columns
          .map((c) => c.key);

      expect(columns, contains('bodyHash'));
      expect(columns, isNot(contains('payload')));
      expect(columns, isNot(contains('email')));
    });
  });
}
