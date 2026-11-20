// An idempotent-provisioning orchestrator necessarily reads and calls its
// AppwriteAdmin dependency far more than its own two fields — that's the
// whole point of separating "what to provision" (this class) from "how"
// (AppwriteAdmin's implementations). Moving this logic onto AppwriteAdmin
// itself would require every implementation (the real one and every test
// fake) to reimplement the same diffing, which is the actual code smell
// this rule is meant to catch.
// ignore_for_file: solid_lints/feature_envy
import 'package:appwrite_schema/appwrite_schema.dart';

import 'package:appwrite_tool/src/appwrite_admin.dart';
import 'package:appwrite_tool/src/mail_settings.dart';
import 'package:appwrite_tool/src/table_access.dart';

/// The Function the mail variables belong to.
const String mailFunctionId = 'api';

/// Auth methods this template's own sign-in flows never use — disabled on
/// every provisioning run.
///
/// **Why (live-verified account-takeover finding):** Appwrite
/// enables every auth method by default on a new project. With
/// `email-password` left on, *any* client can call the public
/// `Account.create(userId, email, password)` endpoint for an arbitrary,
/// unverified email — combined with the live-verified finding that
/// `createEmailToken` looks a user up **by email** and silently reuses
/// whatever account already owns it (see `AppwriteAuthService`'s
/// "Email-code existence finding" dartdoc), that's a real account
/// takeover: an attacker pre-creates `victim@x` with a password of their
/// choosing, the victim later signs up for real via this template's own
/// email-OTP flow and lands in the *attacker's* pre-created account, and
/// the attacker — still holding the password — can sign in as the victim
/// at any time. `magic-url`, `invites`, `jwt` and `phone` are disabled
/// alongside it for the same reason: this template's `AuthService`
/// implements none of them (see that interface's dartdoc — email OTP was
/// chosen deliberately over magic links), so leaving them enabled is
/// unused, unaudited attack surface for no functional benefit. `anonymous`
/// joined this list once guest mode was removed from the template
/// entirely — `AuthService` has no `signInAnonymously` any more, so an
/// enabled `anonymous` method would be unused, unaudited surface for the
/// same reason as the others. `email-otp` (this template's one actual
/// sign-in flow) is the only method deliberately left alone; OAuth
/// providers aren't in this list at all — each is off by default until an
/// app configures real provider credentials for it, so there is nothing to
/// disable.
const List<String> unusedAuthMethods = <String>[
  'email-password',
  'magic-url',
  // Load-bearing for team tenancy: with `invites` disabled, Appwrite
  // refuses every client-side `createMembership` up front, so team roles can
  // only change through the `team_admin` action. Never re-enable it.
  'invites',
  'jwt',
  'phone',
  'anonymous',
];

/// Idempotently provisions an [AppwriteSchema] against an [AppwriteAdmin]:
/// deletes Functions the schema does not declare, creates whatever is
/// missing, updates function settings that drifted, and otherwise does nothing. Safe to run repeatedly — `bin/provision.dart`
/// relies on a second run reporting [ProvisionReport.isNoOp].
class Provisioner {
  /// Creates a provisioner for [schema], applied through [admin]. [mail]
  /// configures outgoing mail (null skips it and says so in the report's
  /// notes); [newSecret] makes the `MAIL_LINK_SECRET` (random by default).
  Provisioner({
    required this.admin,
    required this.schema,
    this.mail,
    String Function()? newSecret,
  }) : _newSecret = newSecret ?? generateMailLinkSecret;

  /// The mail settings from `.env.local`, or null when mail is not
  /// configured.
  final MailSettings? mail;

  final String Function() _newSecret;

  /// The admin operations used to inspect and create resources.
  final AppwriteAdmin admin;

  /// The schema to provision.
  final AppwriteSchema schema;

  /// Applies [schema] to whatever [admin] currently reports, creating only
  /// what's missing.
  Future<ProvisionReport> run() async {
    final changes = <String>[];
    // First, on purpose: removing a Function the schema no longer declares
    // frees its slot (the Free plan allows 2), so the creates
    // below cannot hit `additional_resource_not_allowed`.
    await _deleteUndeclaredFunctions(changes);
    await _disableUnusedAuthMethods(changes);
    await _provisionDatabase(changes);
    for (final table in schema.tables) {
      await _provisionTable(table, changes);
    }
    for (final bucket in schema.buckets) {
      await _provisionBucket(bucket, changes);
    }
    for (final function in schema.functions) {
      await _provisionFunction(function, changes);
    }
    final notes = <String>[];
    await _provisionMail(changes, notes);

    return ProvisionReport(changes, notes: notes);
  }

  /// Email: the Messaging SMTP provider and the `api` Function's
  /// `MAIL_*` variables, each created only when absent (Appwrite hides a
  /// secret on every read, so an existing one is never compared; to rotate
  /// the SMTP password delete the provider and the variable, then
  /// re-provision). Without [mail] nothing is created and a note says so;
  /// the `MAIL_LINK_SECRET` is generated either way because unsubscribe links
  /// need it whatever the SMTP setup.
  Future<void> _provisionMail(List<String> changes, List<String> notes) async {
    final settings = mail;
    if (settings == null) {
      notes.add(
        'mail: skipped, MAIL_SMTP_HOST and MAIL_FROM are not set in '
        '.env.local (no Messaging SMTP provider, no SMTP variables).',
      );
    } else if (!await admin.messagingProviderExists(mailSmtpProviderId)) {
      await admin.createSmtpProvider(
        providerId: mailSmtpProviderId,
        name: mailSmtpProviderName,
        settings: settings,
      );
      changes.add('created Messaging SMTP provider "$mailSmtpProviderId"');
    }
    if (!schema.functions.any((function) => function.id == mailFunctionId)) {
      return;
    }
    final existing = await admin.existingFunctionVariableKeys(mailFunctionId);
    final wanted = <MailVariable>[
      (key: mailLinkSecretVariable, value: _newSecret(), secret: true),
      ...?settings?.functionVariables,
    ];
    for (final variable in wanted) {
      if (existing.contains(variable.key)) continue;
      await admin.createFunctionVariable(
        functionId: mailFunctionId,
        key: variable.key,
        value: variable.value,
        secret: variable.secret,
      );
      changes.add('created variable "$mailFunctionId.${variable.key}"');
    }
  }

  /// Deletes every Function in the project that [schema] does not declare.
  ///
  /// The schema is the source of truth for which Functions exist:
  /// consolidating Functions into the `api` router leaves the old ones
  /// behind, and on the Free plan they hold the slots `api` needs. **A
  /// declared Function is never deleted** - the `declared` check below is
  /// the one guard, and `test/provisioner_test.dart` breaks it on purpose.
  /// Deleting also drops that Function's deployments and variables.
  Future<void> _deleteUndeclaredFunctions(List<String> changes) async {
    final declared = schema.functions.map((function) => function.id).toSet();
    final existing = (await admin.listFunctionIds()).toList()..sort();
    for (final functionId in existing) {
      if (declared.contains(functionId)) continue;
      await admin.deleteFunction(functionId);
      changes.add('deleted function "$functionId" (not in the schema)');
    }
  }

  Future<void> _disableUnusedAuthMethods(List<String> changes) async {
    final enabled = await admin.enabledAuthMethods();
    for (final methodId in unusedAuthMethods) {
      if (!enabled.contains(methodId)) continue;
      await admin.disableAuthMethod(methodId);
      changes.add('disabled auth method "$methodId"');
    }
  }

  Future<void> _provisionDatabase(List<String> changes) async {
    if (await admin.databaseExists(schema.databaseId)) return;
    await admin.createDatabase(
      databaseId: schema.databaseId,
      name: schema.databaseName,
    );
    changes.add('created database "${schema.databaseId}"');
  }

  Future<void> _provisionTable(TableSchema table, List<String> changes) async {
    if (!await admin.tableExists(
      databaseId: schema.databaseId,
      tableId: table.id,
    )) {
      await admin.createTable(
        databaseId: schema.databaseId,
        tableId: table.id,
        name: table.name,
        access: tableAccessOf(table),
      );
      changes.add('created table "${table.id}"');
    } else {
      await _reconcileTableAccess(table, changes);
    }

    await _provisionColumns(table, changes);
    await _provisionIndexes(table, changes);
    await _provisionSeedRows(table, changes);
  }

  /// Repairs an existing table whose table-level permissions or
  /// `rowSecurity` differ from what its `TableAccess` requires (tables
  /// provisioned before the fix carry a blanket
  /// `read/update/delete(Role.users())`). Compared as permission sets.
  Future<void> _reconcileTableAccess(
    TableSchema table,
    List<String> changes,
  ) async {
    final access = tableAccessOf(table);
    final current = await admin.tableSettings(
      databaseId: schema.databaseId,
      tableId: table.id,
    );
    if (!tableAccessDrifted(current, access)) return;
    await admin.updateTableAccess(
      databaseId: schema.databaseId,
      tableId: table.id,
      access: access,
    );
    changes.add('updated table "${table.id}" permissions');
  }

  Future<void> _provisionColumns(
    TableSchema table,
    List<String> changes,
  ) async {
    final existingColumns = await admin.existingColumnKeys(
      databaseId: schema.databaseId,
      tableId: table.id,
    );
    for (final column in table.columns) {
      if (existingColumns.contains(column.key)) continue;
      await admin.createColumn(
        databaseId: schema.databaseId,
        tableId: table.id,
        column: column,
      );
      changes.add('created column "${table.id}.${column.key}"');
    }
  }

  Future<void> _provisionIndexes(
    TableSchema table,
    List<String> changes,
  ) async {
    final existingIndexes = await admin.existingIndexKeys(
      databaseId: schema.databaseId,
      tableId: table.id,
    );
    for (final index in table.indexes) {
      if (existingIndexes.contains(index.key)) continue;
      await admin.createIndex(
        databaseId: schema.databaseId,
        tableId: table.id,
        index: index,
      );
      changes.add('created index "${table.id}.${index.key}"');
    }
  }

  /// Creates each missing seed row; an existing row is left exactly as it
  /// is, so an administrator's edits are never clobbered. Runs after the
  /// columns exist (a row needs them).
  Future<void> _provisionSeedRows(
    TableSchema table,
    List<String> changes,
  ) async {
    for (final row in table.seedRows) {
      if (await admin.rowExists(
        databaseId: schema.databaseId,
        tableId: table.id,
        rowId: row.id,
      )) {
        continue;
      }
      await admin.createRow(
        databaseId: schema.databaseId,
        tableId: table.id,
        rowId: row.id,
        data: row.data,
      );
      changes.add('created row "${table.id}/${row.id}"');
    }
  }

  Future<void> _provisionBucket(
    BucketSchema bucket,
    List<String> changes,
  ) async {
    if (await admin.bucketExists(bucket.id)) return;
    await admin.createBucket(
      bucketId: bucket.id,
      name: bucket.name,
      fileSecurity: bucket.fileSecurity,
    );
    changes.add('created bucket "${bucket.id}"');
  }

  Future<void> _provisionFunction(
    FunctionSchema function,
    List<String> changes,
  ) async {
    final current = await admin.getFunction(function.id);
    if (current == null) {
      await admin.createFunction(function);
      changes.add('created function "${function.id}"');
    } else if (_functionDrifted(current, function)) {
      await admin.updateFunction(function);
      changes.add('updated function "${function.id}"');
    }

    await _provisionFunctionVariables(function, changes);
  }

  Future<void> _provisionFunctionVariables(
    FunctionSchema function,
    List<String> changes,
  ) async {
    final existingVariables = await admin.existingFunctionVariableKeys(
      function.id,
    );
    for (final entry in function.variables.entries) {
      if (existingVariables.contains(entry.key)) continue;
      await admin.createFunctionVariable(
        functionId: function.id,
        key: entry.key,
        value: entry.value,
      );
      changes.add('created variable "${function.id}.${entry.key}"');
    }
  }

  /// Compares [current] against [schema], ignoring order in the `execute`
  /// and `scopes` lists (Appwrite treats both as sets, not sequences).
  bool _functionDrifted(FunctionSettings current, FunctionSchema schema) {
    return current.name != schema.name ||
        current.entrypoint != schema.entrypoint ||
        current.commands != schema.commands ||
        current.timeout != schema.timeout ||
        current.schedule != schema.schedule ||
        !_sameSet(current.execute, schema.execute) ||
        !_sameSet(current.scopes, schema.scopes);
  }

  bool _sameSet(List<String> first, List<String> second) {
    final firstSet = first.toSet();
    final secondSet = second.toSet();

    return firstSet.containsAll(secondSet) && secondSet.containsAll(firstSet);
  }
}

/// What `Provisioner.run` did: every resource it created, keyed by a
/// human-readable description. Empty means the schema was already fully
/// provisioned — a true no-op.
class ProvisionReport {
  /// Creates a report wrapping the list of changes made.
  ProvisionReport(this.changes, {this.notes = const <String>[]});

  /// What was skipped on purpose and why (mail without SMTP settings); never
  /// a change, so it does not make [isNoOp] false.
  final List<String> notes;

  /// One entry per resource created or updated, in the order it happened.
  final List<String> changes;

  /// True if nothing needed to change.
  bool get isNoOp => changes.isEmpty;
}
