import 'package:appwrite_schema/src/api_key_schema.dart';
import 'package:appwrite_schema/src/bucket_schema.dart';
import 'package:appwrite_schema/src/column_schema.dart';
import 'package:appwrite_schema/src/function_schema.dart';
import 'package:appwrite_schema/src/owned_file_ref.dart';
import 'package:appwrite_schema/src/seed_row.dart';
import 'package:appwrite_schema/src/site_schema.dart';
import 'package:appwrite_schema/src/table_index_schema.dart';
import 'package:appwrite_schema/src/table_ownership.dart';
import 'package:appwrite_schema/src/table_schema.dart';

/// The full backend schema: one database, its tables, storage buckets and
/// Functions.
class AppwriteSchema {
  /// Creates a schema.
  const AppwriteSchema({
    required this.databaseId,
    required this.databaseName,
    required this.tables,
    required this.buckets,
    required this.functions,
    this.sites = const <SiteSchema>[],
    this.apiKeys = const <ApiKeySchema>[],
  });

  /// The `TablesDB` database ID.
  final String databaseId;

  /// The database's display name.
  final String databaseName;

  /// The database's tables.
  final List<TableSchema> tables;

  /// The project's storage buckets.
  final List<BucketSchema> buckets;

  /// The project's Functions.
  final List<FunctionSchema> functions;

  /// The project's Sites (static web builds).
  final List<SiteSchema> sites;

  /// The narrowly scoped API keys the tooling uses, one per component.
  final List<ApiKeySchema> apiKeys;
}

/// The template's default backend schema.
///
/// `profiles` backs `package:domain`'s `UserProfile` placeholder model — see
/// that model's dartdoc for why it exists and why apps are expected to
/// replace it. Kept intentionally small: one user-owned table with one file
/// reference, enough to exercise every code path `bin/provision.dart` and
/// `delete_account` need (a plain column, a nullable column, a unique
/// index, and an owned bucket file) without inventing product-specific
/// shape a cloned app would just delete anyway.
const AppwriteSchema templateSchema = AppwriteSchema(
  databaseId: 'main',
  databaseName: 'Main',
  tables: <TableSchema>[
    // Publicly readable (see `TableSchema.publicRead`): the bootstrap/
    // splash screen's `VersionPolicy` check (`AppwriteVersionPolicy` in
    // `backend/appwrite/adapters`) reads its single fixed row (id
    // `'default'`) before any session exists. `bin/provision.dart` creates
    // that row when it is absent (see `seedRows` below) and never
    // overwrites it afterwards; a backend administrator then manages it by
    // hand (console or a script).
    TableSchema(
      id: 'app_config',
      name: 'App Config',
      publicRead: true,
      // `minSupportedVersion: '0.0.0'` is the "nothing is blocked" value:
      // `AppwriteVersionPolicy.check` blocks only when the running app is
      // older than this, and no app version is older than 0.0.0 - so the
      // check passes for the template's current app (`AppConfig`'s
      // placeholder `appVersion` is `1.0.0`) and for any clone. The three
      // update URLs and the message are optional columns and are left unset
      // (an unset URL means a blocked app would get no store link). Raise
      // `minSupportedVersion` in the console to force an update.
      seedRows: <SeedRow>[
        SeedRow(
          id: 'default',
          data: <String, Object>{'minSupportedVersion': '0.0.0'},
        ),
      ],
      columns: <ColumnSchema>[
        ColumnSchema(
          key: 'minSupportedVersion',
          type: ColumnType.varchar,
          size: 32,
        ),
        ColumnSchema(
          key: 'updateUrlIOS',
          type: ColumnType.text,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'updateUrlAndroid',
          type: ColumnType.text,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'updateUrlWeb',
          type: ColumnType.text,
          isRequired: false,
        ),
        ColumnSchema(key: 'message', type: ColumnType.text, isRequired: false),
      ],
    ),
    TableSchema(
      id: 'profiles',
      name: 'Profiles',
      columns: <ColumnSchema>[
        ColumnSchema(key: 'userId', type: ColumnType.varchar),
        ColumnSchema(key: 'displayName', type: ColumnType.text),
        ColumnSchema(
          key: 'avatarFileId',
          type: ColumnType.text,
          isRequired: false,
        ),
      ],
      ownership: TableOwnership(
        userIdColumn: 'userId',
        fileRefs: <OwnedFileRef>[
          OwnedFileRef(column: 'avatarFileId', bucketId: 'avatars'),
        ],
      ),
      indexes: <TableIndexSchema>[
        TableIndexSchema(
          key: 'userId_unique',
          columns: <String>['userId'],
          unique: true,
        ),
      ],
    ),
    // Team tenancy. `team_invitations` and
    // `team_membership_events` are `serverOnly`: only the `team_admin`
    // action of `api` (an API key) may touch them, so a client can neither
    // forge a history entry nor read another team's. `team_notes` is the
    // example team-scoped table (`AppwriteDocumentRepository.create` with a
    // `TeamScope`): a clone replaces it with its own shared data.
    TableSchema(
      id: 'team_invitations',
      name: 'Team Invitations',
      serverOnly: true,
      columns: <ColumnSchema>[
        ColumnSchema(key: 'teamId', type: ColumnType.varchar),
        ColumnSchema(key: 'teamName', type: ColumnType.varchar),
        ColumnSchema(key: 'email', type: ColumnType.varchar),
        ColumnSchema(key: 'role', type: ColumnType.varchar),
        ColumnSchema(key: 'invitedBy', type: ColumnType.varchar),
        ColumnSchema(key: 'status', type: ColumnType.varchar),
        ColumnSchema(key: 'createdAt', type: ColumnType.varchar, size: 40),
        ColumnSchema(key: 'expiresAt', type: ColumnType.varchar, size: 40),
      ],
      indexes: <TableIndexSchema>[
        TableIndexSchema(key: 'teamId_key', columns: <String>['teamId']),
        TableIndexSchema(key: 'email_key', columns: <String>['email']),
      ],
    ),
    TableSchema(
      id: 'team_membership_events',
      name: 'Team Membership Events',
      serverOnly: true,
      columns: <ColumnSchema>[
        ColumnSchema(key: 'teamId', type: ColumnType.varchar),
        ColumnSchema(key: 'type', type: ColumnType.varchar),
        ColumnSchema(key: 'actorUserId', type: ColumnType.varchar),
        ColumnSchema(
          key: 'actorEmail',
          type: ColumnType.varchar,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'subjectUserId',
          type: ColumnType.varchar,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'subjectEmail',
          type: ColumnType.varchar,
          isRequired: false,
        ),
        ColumnSchema(key: 'role', type: ColumnType.varchar, isRequired: false),
        ColumnSchema(
          key: 'previousRole',
          type: ColumnType.varchar,
          isRequired: false,
        ),
        ColumnSchema(key: 'at', type: ColumnType.varchar, size: 40),
      ],
      indexes: <TableIndexSchema>[
        TableIndexSchema(key: 'teamId_key', columns: <String>['teamId']),
        // The retention job's `Query.lessThan('at', cutoff)`;
        // `at` is a UTC ISO-8601 string, so string order is time order.
        TableIndexSchema(key: 'at_key', columns: <String>['at']),
      ],
    ),
    TableSchema(
      id: 'team_notes',
      name: 'Team Notes',
      columns: <ColumnSchema>[
        ColumnSchema(key: 'userId', type: ColumnType.varchar),
        ColumnSchema(key: 'teamId', type: ColumnType.varchar),
        ColumnSchema(key: 'body', type: ColumnType.text),
      ],
      indexes: <TableIndexSchema>[
        TableIndexSchema(key: 'userId_key', columns: <String>['userId']),
        TableIndexSchema(key: 'teamId_key', columns: <String>['teamId']),
      ],
    ),
    // Server primitives for background work. All `serverOnly`:
    // only the `api` router's code (an API key) touches them, never a client.
    // Numbers and times are stored as strings (the schema has no integer
    // column type); times are UTC ISO-8601, so string order is time order.
    //
    // `jobs` + `job_claims`: the leased queue (`JobQueueEngine`). TablesDB
    // has no compare-and-set, so a claim is a row unique on (jobId, attempt);
    // `jobs.status` is only a cache that narrows the claim query.
    TableSchema(
      id: 'jobs',
      name: 'Jobs',
      serverOnly: true,
      columns: <ColumnSchema>[
        ColumnSchema(key: 'type', type: ColumnType.varchar),
        ColumnSchema(key: 'payload', type: ColumnType.text),
        ColumnSchema(key: 'priority', type: ColumnType.varchar, size: 16),
        ColumnSchema(key: 'maxAttempts', type: ColumnType.varchar, size: 8),
        ColumnSchema(key: 'availableAt', type: ColumnType.varchar, size: 40),
        ColumnSchema(key: 'createdAt', type: ColumnType.varchar, size: 40),
        ColumnSchema(key: 'sortKey', type: ColumnType.varchar, size: 64),
        ColumnSchema(key: 'status', type: ColumnType.varchar, size: 16),
        ColumnSchema(
          key: 'leaseUntil',
          type: ColumnType.varchar,
          size: 40,
          isRequired: false,
        ),
      ],
      indexes: <TableIndexSchema>[
        TableIndexSchema(key: 'status_key', columns: <String>['status']),
        TableIndexSchema(key: 'type_key', columns: <String>['type']),
        TableIndexSchema(key: 'sortKey_key', columns: <String>['sortKey']),
        TableIndexSchema(
          key: 'availableAt_key',
          columns: <String>['availableAt'],
        ),
        TableIndexSchema(
          key: 'leaseUntil_key',
          columns: <String>['leaseUntil'],
        ),
      ],
    ),
    TableSchema(
      id: 'job_claims',
      name: 'Job Claims',
      serverOnly: true,
      columns: <ColumnSchema>[
        ColumnSchema(key: 'jobId', type: ColumnType.varchar, size: 64),
        ColumnSchema(key: 'attempt', type: ColumnType.varchar, size: 8),
        ColumnSchema(key: 'workerId', type: ColumnType.varchar),
        ColumnSchema(key: 'leaseExpiresAt', type: ColumnType.varchar, size: 40),
        ColumnSchema(key: 'state', type: ColumnType.varchar, size: 16),
        ColumnSchema(key: 'result', type: ColumnType.text, isRequired: false),
        ColumnSchema(key: 'error', type: ColumnType.text, isRequired: false),
        ColumnSchema(
          key: 'finishedAt',
          type: ColumnType.varchar,
          size: 40,
          isRequired: false,
        ),
      ],
      indexes: <TableIndexSchema>[
        // The one atomic rule the queue rests on: one claim per attempt.
        TableIndexSchema(
          key: 'jobId_attempt_unique',
          columns: <String>['jobId', 'attempt'],
          unique: true,
        ),
        TableIndexSchema(key: 'jobId_key', columns: <String>['jobId']),
      ],
    ),
    // `job_slots`: one row per (scheduled job, slot), unique, so a cron tick
    // delivered twice runs the job once (`OncePerSlotJob`).
    TableSchema(
      id: 'job_slots',
      name: 'Job Slots',
      serverOnly: true,
      columns: <ColumnSchema>[
        ColumnSchema(key: 'jobName', type: ColumnType.varchar, size: 64),
        ColumnSchema(key: 'slot', type: ColumnType.varchar, size: 20),
        ColumnSchema(key: 'claimedAt', type: ColumnType.varchar, size: 40),
      ],
      indexes: <TableIndexSchema>[
        TableIndexSchema(
          key: 'jobName_slot_unique',
          columns: <String>['jobName', 'slot'],
          unique: true,
        ),
        // The housekeeping job's `claimedAt < cutoff` sweep.
        TableIndexSchema(key: 'claimedAt_key', columns: <String>['claimedAt']),
      ],
    ),
    // `rate_limits`: one row per hit inside a window (`RateLimiter`), keyed by
    // an HMAC of the caller's IP or host, never the raw value. A row dies at
    // `expiresAt` (the window's end); the housekeeping job deletes it.
    TableSchema(
      id: 'rate_limits',
      name: 'Rate Limits',
      serverOnly: true,
      columns: <ColumnSchema>[
        ColumnSchema(key: 'keyHash', type: ColumnType.varchar, size: 64),
        ColumnSchema(key: 'windowStart', type: ColumnType.varchar, size: 20),
        ColumnSchema(key: 'hit', type: ColumnType.varchar, size: 8),
        ColumnSchema(key: 'expiresAt', type: ColumnType.varchar, size: 40),
      ],
      indexes: <TableIndexSchema>[
        TableIndexSchema(
          key: 'keyHash_window_hit_unique',
          columns: <String>['keyHash', 'windowStart', 'hit'],
          unique: true,
        ),
        TableIndexSchema(
          key: 'keyHash_window_key',
          columns: <String>['keyHash', 'windowStart'],
        ),
        TableIndexSchema(key: 'expiresAt_key', columns: <String>['expiresAt']),
      ],
    ),
    // Email, both `serverOnly`: `mail_deliveries` is the
    // idempotency record `MailerEngine` claims before it sends (unique on a
    // SHA-256 of the idempotency key, the same 409 mechanism as `job_claims`),
    // and holds no address and no body. `mail_suppressions` is the
    // unsubscribe / bounce list, unique per (user, subscription).
    TableSchema(
      id: 'mail_deliveries',
      name: 'Mail Deliveries',
      serverOnly: true,
      columns: <ColumnSchema>[
        ColumnSchema(key: 'keyHash', type: ColumnType.varchar, size: 64),
        ColumnSchema(key: 'userId', type: ColumnType.varchar),
        ColumnSchema(key: 'templateId', type: ColumnType.varchar),
        ColumnSchema(key: 'locale', type: ColumnType.varchar, size: 16),
        ColumnSchema(key: 'status', type: ColumnType.varchar, size: 16),
        ColumnSchema(key: 'createdAt', type: ColumnType.varchar, size: 40),
        ColumnSchema(
          key: 'providerMessageId',
          type: ColumnType.varchar,
          size: 64,
          isRequired: false,
        ),
        ColumnSchema(key: 'detail', type: ColumnType.text, isRequired: false),
      ],
      indexes: <TableIndexSchema>[
        TableIndexSchema(
          key: 'keyHash_unique',
          columns: <String>['keyHash'],
          unique: true,
        ),
        // The housekeeping job's `createdAt < cutoff` sweep.
        TableIndexSchema(key: 'createdAt_key', columns: <String>['createdAt']),
      ],
    ),
    TableSchema(
      id: 'mail_suppressions',
      name: 'Mail Suppressions',
      serverOnly: true,
      columns: <ColumnSchema>[
        ColumnSchema(key: 'userId', type: ColumnType.varchar),
        ColumnSchema(key: 'subscription', type: ColumnType.varchar, size: 64),
        ColumnSchema(key: 'reason', type: ColumnType.varchar, size: 16),
        ColumnSchema(key: 'createdAt', type: ColumnType.varchar, size: 40),
      ],
      indexes: <TableIndexSchema>[
        TableIndexSchema(
          key: 'userId_subscription_unique',
          columns: <String>['userId', 'subscription'],
          unique: true,
        ),
      ],
    ),
    // Web billing, both `serverOnly`. `billing_events` is the
    // append-only ledger: one row per provider event change, unique on
    // `ledgerKey` (the event ID, or `<event id>#<n>`), written only by the
    // `hooks` Function before it touches an entitlement, and **never deleted**
    // (GoBD): no retention rule covers it. It keeps what the event said about
    // the subscription and a SHA-256 of the raw body, not the payload.
    // `billing_entitlements` is one row per provider subscription, written by
    // `hooks` (webhook) and the reconciler; a client reads it only through the
    // `billing` action. Numbers are strings (the schema has no integer type).
    TableSchema(
      id: 'billing_events',
      name: 'Billing Events',
      serverOnly: true,
      columns: <ColumnSchema>[
        ColumnSchema(key: 'ledgerKey', type: ColumnType.varchar, size: 96),
        ColumnSchema(key: 'eventId', type: ColumnType.varchar, size: 64),
        ColumnSchema(key: 'eventType', type: ColumnType.varchar, size: 64),
        ColumnSchema(key: 'kind', type: ColumnType.varchar, size: 24),
        ColumnSchema(key: 'occurredAt', type: ColumnType.varchar, size: 40),
        ColumnSchema(key: 'receivedAt', type: ColumnType.varchar, size: 40),
        ColumnSchema(key: 'bodyHash', type: ColumnType.varchar, size: 64),
        ColumnSchema(
          key: 'subscriptionId',
          type: ColumnType.varchar,
          size: 64,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'ownerKey',
          type: ColumnType.varchar,
          size: 80,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'status',
          type: ColumnType.varchar,
          size: 16,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'quantity',
          type: ColumnType.varchar,
          size: 12,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'plan',
          type: ColumnType.varchar,
          size: 64,
          isRequired: false,
        ),
        ColumnSchema(key: 'detail', type: ColumnType.text, isRequired: false),
      ],
      indexes: <TableIndexSchema>[
        TableIndexSchema(
          key: 'ledgerKey_unique',
          columns: <String>['ledgerKey'],
          unique: true,
        ),
        TableIndexSchema(key: 'eventId_key', columns: <String>['eventId']),
        TableIndexSchema(
          key: 'subscriptionId_key',
          columns: <String>['subscriptionId'],
        ),
      ],
    ),
    TableSchema(
      id: 'billing_entitlements',
      name: 'Billing Entitlements',
      serverOnly: true,
      columns: <ColumnSchema>[
        ColumnSchema(key: 'subscriptionId', type: ColumnType.varchar, size: 64),
        ColumnSchema(key: 'ownerKey', type: ColumnType.varchar, size: 80),
        ColumnSchema(key: 'plan', type: ColumnType.varchar, size: 64),
        ColumnSchema(key: 'quantity', type: ColumnType.varchar, size: 12),
        ColumnSchema(key: 'status', type: ColumnType.varchar, size: 16),
        ColumnSchema(key: 'eventAt', type: ColumnType.varchar, size: 40),
        ColumnSchema(key: 'source', type: ColumnType.varchar, size: 16),
        ColumnSchema(key: 'reconciledAt', type: ColumnType.varchar, size: 40),
        ColumnSchema(
          key: 'customerId',
          type: ColumnType.varchar,
          size: 64,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'currentPeriodEnd',
          type: ColumnType.varchar,
          size: 40,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'nextBilledAt',
          type: ColumnType.varchar,
          size: 40,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'canceledAt',
          type: ColumnType.varchar,
          size: 40,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'pastDueSince',
          type: ColumnType.varchar,
          size: 40,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'scheduledAction',
          type: ColumnType.varchar,
          size: 16,
          isRequired: false,
        ),
        ColumnSchema(
          key: 'scheduledAt',
          type: ColumnType.varchar,
          size: 40,
          isRequired: false,
        ),
      ],
      indexes: <TableIndexSchema>[
        TableIndexSchema(
          key: 'subscriptionId_unique',
          columns: <String>['subscriptionId'],
          unique: true,
        ),
        TableIndexSchema(key: 'ownerKey_key', columns: <String>['ownerKey']),
        // The reconciler's "not canceled, compared longest ago first".
        TableIndexSchema(key: 'status_key', columns: <String>['status']),
        TableIndexSchema(
          key: 'reconciledAt_key',
          columns: <String>['reconciledAt'],
        ),
      ],
    ),
  ],
  buckets: <BucketSchema>[BucketSchema(id: 'avatars', name: 'Avatars')],
  // At most 2 Functions (`maxFunctions`): Appwrite Cloud's Free plan allows 2
  // per project. One router `api` Function serves every server-side
  // operation as a named action (decision of 2026-10-01);
  // `hooks` receives public inbound webhooks - see `maxFunctions`.
  functions: <FunctionSchema>[
    FunctionSchema(
      id: 'api',
      name: 'API',
      runtime: 'dart-3.12',
      entrypoint: 'lib/main.dart',
      path: 'backend/appwrite/functions/api',
      // Callable with no session: the `review_demo_sign_in` action must be
      // (a store reviewer has none; this is *not* the
      // account-takeover hole `unusedAuthMethods` closes, the action
      // accepts only a shared review code, never an email). Authentication
      // is therefore enforced per action by the router
      // (`ApiAction.requiresUser`), from the `x-appwrite-user-id` header.
      execute: <String>['any'],
      // One cron tick every five minutes dispatches the due scheduled jobs
      // (`ScheduledJob`); an empty registry just returns.
      schedule: apiCronSchedule,
      // Exactly the union of every action's (and scheduled job's) own
      // `scopes` - `backend/appwrite/functions/api/test/scopes_test.dart`
      // fails on any difference. A Function has one key scope set, so
      // each action declares what it needs and the union is declared here.
      scopes: <String>[
        'tables.read',
        'tables.write',
        'collections.read',
        'collections.write',
        'documents.read',
        'documents.write',
        'files.read',
        'files.write',
        'users.read',
        'users.write',
        'teams.read',
        'teams.write',
        // Appwrite Messaging, for transactional mail.
        'messages.read',
        'messages.write',
      ],
    ),
    // The second Function slot: public, unauthenticated inbound
    // webhooks, each verified with its own signature and routed by path
    // (`/paddle`). Its key is **not** `api`'s: it may only touch database
    // rows, so the code that writes the billing ledger holds no user, team
    // or messaging scope. `execute: any` because Paddle has no session.
    FunctionSchema(
      id: 'hooks',
      name: 'Hooks',
      runtime: 'dart-3.12',
      entrypoint: 'lib/main.dart',
      path: 'backend/appwrite/functions/hooks',
      execute: <String>['any'],
      scopes: <String>[
        'tables.read',
        'tables.write',
        'collections.read',
        'collections.write',
        'documents.read',
        'documents.write',
      ],
    ),
  ],
  sites: <SiteSchema>[
    SiteSchema(
      id: 'app',
      name: 'App',
      buildOutputPath: 'apps/app/build/web',
      buildCommand:
          'cd apps/app && fvm flutter build web --dart-define=BACKEND=appwrite '
          '--no-web-resources-cdn',
      // Flutter web is a single-page app; every route is client-side.
      fallbackFile: 'index.html',
    ),
    SiteSchema(
      id: 'website',
      name: 'Website',
      buildOutputPath: 'apps/website/build/jaspr',
      buildCommand: 'fvm dart run melos run website:build',
    ),
  ],
  apiKeys: <ApiKeySchema>[
    ApiKeySchema(
      id: 'provisioner',
      name: 'provisioner',
      purpose: 'bin/provision.dart (schema provisioning, auth methods)',
      scopes: <String>[
        'project.read',
        'project.write',
        'databases.read',
        'databases.write',
        'tables.read',
        'tables.write',
        'collections.read',
        'collections.write',
        'attributes.read',
        'attributes.write',
        'columns.read',
        'columns.write',
        'indexes.read',
        'indexes.write',
        'documents.read',
        'documents.write',
        'buckets.read',
        'buckets.write',
        'functions.read',
        'functions.write',
        'sites.read',
        'sites.write',
        // The mail SMTP provider.
        'providers.read',
        'providers.write',
      ],
    ),
    ApiKeySchema(
      id: 'deployer',
      name: 'deployer',
      purpose: 'bin/deploy.dart and bin/deploy_site.dart (Functions, Sites)',
      scopes: <String>[
        'functions.read',
        'functions.write',
        'sites.read',
        'sites.write',
      ],
    ),
    ApiKeySchema(
      id: 'review-demo-seeder',
      name: 'review-demo-seeder',
      purpose: 'bin/seed_review_demo_account.dart',
      scopes: <String>[
        'users.read',
        'users.write',
        'functions.read',
        'functions.write',
      ],
    ),
  ],
);
